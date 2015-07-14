//
//  ChatCollectionViewDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/19/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatCollectionViewDataSource: NSObject,  JSQMessagesCollectionViewDataSource {
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
    var messages: [JSQMessage]?
    var otherPerson: Person?
    func senderDisplayName() -> String! {
        return delegate?.senderDisplayName
    }
    func senderId() -> String! {
        return delegate?.senderId
    }
    
    //MARK: - JSQMessagesCollectionViewDataSource Methods
    
    //Setting up the labels around the bubble
    func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return NSAttributedString(string: messages![indexPath.item].senderDisplayName)
    }
    func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(messages![indexPath.item].date)
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
        if messages![indexPath.item].senderId == senderId() {
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(Constants.OutgoingBubble.bubbleColor)
        } else {
            return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(Constants.IncomingBubble.bubbleColor)
        }
    }
    //Getting the actual data for the bubble
    func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages![indexPath.item]
    }
    
    //MARK: - UICollectionViewDataSource Methods
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = delegate?.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
        let message = messages![indexPath.item]
        
        cell?.textView.textColor = message.senderId == senderId() ? Constants.OutgoingBubble.textColor : Constants.IncomingBubble.textColor
        cell?.textView.text = message.text
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages!.count
    }
    
    //MARK: - Button Action Methods
    func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        messages!.append(JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text))
    }
    
}
