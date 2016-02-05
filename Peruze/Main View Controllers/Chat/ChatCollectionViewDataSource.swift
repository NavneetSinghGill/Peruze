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
  var latestMessageDate: NSDate!
  
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
    if self.latestMessageDate != nil {
       self.getChatAfterDate(self.latestMessageDate)
    }
  }
    
    func removeNoti() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "NewChat", object: nil)
    }
    
    func getChat() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.getChatData()
        dispatch_async(dispatch_get_main_queue()){
            self.delegate?.collectionView?.reloadData()
            self.scrollToBottom()
        }
    }
    func getChatData() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
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
        if fetchedResultsController.sections != nil {
            let numberOfMessages = fetchedResultsController.sections?[0].numberOfObjects ?? 0
            dispatch_async(dispatch_get_main_queue()){
                self.delegate?.collectionView?.reloadData()
            }
            if numberOfMessages >= 1 {
                let indexPath = NSIndexPath(forItem: numberOfMessages - 1, inSection: 0)
                let message = JSQMessageFromMessage(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
                self.latestMessageDate = message.valueForKey("date") as! NSDate
            }
        }
    }
    
    func getChatAfterDate(messageDate: NSDate) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with messageDate: \(messageDate)")
        //Fetching all chat after date
        var exchangeReferences = [CKReference]()
        let recordID = CKRecordID(recordName: self.exchange.valueForKey("recordIDName") as! String)
        let recordRef = CKReference(recordID: recordID, action: .None)
        exchangeReferences.append(recordRef)
        
        let messagesPredicate = NSPredicate(format: "Exchange IN %@", exchangeReferences)
        let datePredicate = NSPredicate(format: "modificationDate > %@", messageDate)
        let messagesQuery = CKQuery(recordType: RecordTypes.Message, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [messagesPredicate, datePredicate]))
        let messagesQueryOp = CKQueryOperation(query: messagesQuery)
        
        
        //Add the messages to the database and save the context
        messagesQueryOp.recordFetchedBlock = { (record: CKRecord!) -> Void in
            
            let localMessage = Message.MR_findFirstOrCreateByAttribute("recordIDName",
                withValue: record.recordID.recordName, inContext: managedConcurrentObjectContext)
            
            if let messageText = record.objectForKey("Text") as? String {
                localMessage.setValue(messageText, forKey: "text")
            }
            
            if let messageImage = record.objectForKey("Image") as? CKAsset {
                localMessage.setValue(NSData(contentsOfURL: messageImage.fileURL), forKey: "image")
            }
            
            localMessage.setValue(record.objectForKey("Date") as? NSDate, forKey: "date")
            
            if let exchange = record.objectForKey("Exchange") as? CKReference {
                let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
                    withValue: exchange.recordID.recordName,
                    inContext: managedConcurrentObjectContext)
                localMessage.setValue(messageExchange, forKey: "exchange")
            }
            
            if let receiverRecordIDName = record.objectForKey("ReceiverRecordIDName") as? String {
                localMessage.setValue(receiverRecordIDName, forKey: "receiverRecordIDName")
            }
            
            if let senderRecordIDName = record.objectForKey("SenderRecordIDName") as? String {
                localMessage.setValue(senderRecordIDName, forKey: "senderRecordIDName")
            }
            
            if record.creatorUserRecordID?.recordName == "__defaultOwner__" {
                let sender = Person.MR_findFirstOrCreateByAttribute("me",
                    withValue: true,
                    inContext: managedConcurrentObjectContext)
                localMessage.setValue(sender, forKey: "sender")
            } else {
                let sender = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                    withValue: record.creatorUserRecordID?.recordName,
                    inContext: managedConcurrentObjectContext)
                localMessage.setValue(sender, forKey: "sender")
            }
            
            managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
            self.getChatData()
        }
        
        //Finish this operation
        messagesQueryOp.queryCompletionBlock = { (cursor, error) -> Void in
            if let error = error {
                logw("Get Chats For Accepted Exchanges Operation Finished with error: ")
                logw("\(error)")
            }
        }
        
        //add the operation to the database
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(messagesQueryOp)
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
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let postMessageOp = PostMessageOperation(
      date: date ?? NSDate(timeIntervalSinceNow: 0),
      text: text,
      image: nil,
      exchangeRecordIDName: exchange.valueForKey("recordIDName") as! String,
      database: CKContainer.defaultContainer().publicCloudDatabase,
      context: managedConcurrentObjectContext) {
        //do something
        dispatch_async(dispatch_get_main_queue()){
            logw("\(_stdlib_getDemangledTypeName(self))) PostMessageOperation finished.")
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
