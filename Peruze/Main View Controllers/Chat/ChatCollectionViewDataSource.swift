//
//  ChatCollectionViewDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/19/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

class ChatCollectionViewDataSource: NSObject,  JSQMessagesCollectionViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    struct OutgoingBubble {
      static let bubbleColor = UIColor.jsq_messageBubbleLightGrayColor()
      static let textColor = UIColor.blackColor()
    }
    struct IncomingBubble {
      static let bubbleColor = UIColor.jsq_messageBubbleRedColor()
      static let textColor = UIColor.whiteColor()
    }
  }
  
  var delegate: JSQMessagesViewController?
  var fetchedResultsController: NSFetchedResultsController!
  var otherPerson: Person?
  var exchange: NSManagedObject
  
  func senderDisplayName() -> String! {
    return delegate?.senderDisplayName
  }
  
  func senderId() -> String! {
    return delegate?.senderId
  }
  
  //MARK: - JSQMessagesCollectionViewDataSource Methods
  init(exchange: NSManagedObject) {
    self.exchange = exchange
    super.init()
    self.getChatData()
  }
  
    func getChatData() {
        //    let exchangePredicate = NSPredicate(value: true)
        let exchangePredicate = NSPredicate(format: "exchange.recordIDName == %@", self.exchange.valueForKey("recordIDName") as! String)
        fetchedResultsController = Message.MR_fetchAllSortedBy(
            "date",
            ascending: true,
            withPredicate: exchangePredicate,
            groupBy: nil,
            delegate: self,
            inContext: managedConcurrentObjectContext
        )
    }
    
  //Setting up the labels around the bubble
  func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    let message = JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
    return NSAttributedString(string: message.senderDisplayName)
  }
  
  func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    let message = JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
    
    return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
  }
  
  func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    return nil
  }
  
  //Setting up the avatar and bubble
  func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
    //TODO: Implement this
    return nil
  }
  
  func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
    let message = JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
    if message.senderId == senderId() {
      return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(Constants.OutgoingBubble.bubbleColor)
    } else {
      return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(Constants.IncomingBubble.bubbleColor)
    }
  }
  
  //Getting the actual data for the bubble
  func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
    return JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
  }
  
  //MARK: - UICollectionViewDataSource Methods
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = delegate?.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
    let message = JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
    
    cell?.textView?.textColor = message.senderId == senderId() ? Constants.OutgoingBubble.textColor : Constants.IncomingBubble.textColor
    cell?.textView?.text = message.text
    return cell ?? UICollectionViewCell()
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  //MARK: - Button Action Methods
  func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
    let postMessageOp = PostMessageOperation(
      date: date ?? NSDate(timeIntervalSinceNow: 0),
      text: text,
      image: nil,
      exchangeRecordIDName: exchange.valueForKey("recordIDName") as! String,
      database: CKContainer.defaultContainer().publicCloudDatabase,
      context: managedConcurrentObjectContext) {
        //do something
        dispatch_async(dispatch_get_main_queue()){
            self.getChatData()
            self.delegate?.collectionView?.reloadData()
            self.scrollToBottom()
        }
    }
    OperationQueue().addOperation(postMessageOp)
  }
    
    func scrollToBottom() {
        let sections = self.delegate?.collectionView?.numberOfSections()
        let rows = self.delegate?.collectionView?.numberOfItemsInSection(sections! - 1)
        let indexPath = NSIndexPath(forRow: rows! - 1, inSection: sections! - 1)
        if indexPath.row >= 0 && indexPath.section >= 0 {
            self.delegate?.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
        }
    }
  
  private func JSQMessageFromMessage(message: NSManagedObject) -> JSQMessage {
    //Swift 2.0
    //    guard
    //      let date = message.valueForKey("date") as? NSDate,
    //      let sender = message.valueForKey("sender") as? NSManagedObject,
    //      let senderId = sender.valueForKey("recordIDName") as? String,
    //      let senderDisplayName = sender.valueForKey("firstName") as? String
    //      else {
    //        logw("Error: Vital message information was nil.")
    //        return JSQMessage()
    //    }
    
    let date = message.valueForKey("date") as! NSDate
    let sender = message.valueForKey("sender") as! NSManagedObject
    let senderId = sender.valueForKey("recordIDName") as! String
    let senderDisplayName = sender.valueForKey("firstName") as! String
    
    if let imageData = message.valueForKey("image") as? NSData {
      let media = JSQPhotoMediaItem(image: UIImage(data: imageData))
      let message = JSQMessage(
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        date: date,
        media: media)
      return message
    }
    
    if let text = message.valueForKey("text") as? String {
      let message = JSQMessage(
        senderId: senderId,
        senderDisplayName: senderDisplayName,
        date: date,
        text: text)
      return message
    }
    logw("Error: There was no text or imageData.")
    return JSQMessage()
  }
}
