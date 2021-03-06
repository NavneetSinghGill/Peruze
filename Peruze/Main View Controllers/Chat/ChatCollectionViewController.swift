//
//  ChatCollectionViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ChatCollectionViewController: JSQMessagesViewController, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TGCameraDelegate {
  private struct Constants {
    static let BufferSize: CGFloat = 8
  }
  var delegate: ChatDeletionDelegate?
  var exchange: NSManagedObject!
  var dataSource: ChatCollectionViewDataSource? {
    didSet {
      dataSource!.delegate = self
      collectionView!.dataSource = dataSource
    }
  }
  
  private var sendButton: UIButton?
  private var cancelButton: UIButton?
  private var completeButton: UIButton?
  private var attachmentButton: UIButton?
  var presentationContext: UIViewController!
    
    
  //MARK: - Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //get notifications from keyboard
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive", name: "applicationDidBecomeActive", object: nil)
    dataSource = ChatCollectionViewDataSource(exchange: exchange)
    
    //set the properties of the input toolbar
    inputToolbar?.contentView?.tintColor = .redColor()
    inputToolbar?.contentView?.rightBarButtonItem?.setTitleColor(UIColor.redColor(), forState: .Normal)
    inputToolbar?.contentView?.rightBarButtonItem?.setTitleColor(UIColor.redColor(), forState: .Highlighted)
    
    //store the send button and attachment button
    sendButton = inputToolbar?.contentView?.rightBarButtonItem
    attachmentButton = inputToolbar?.contentView?.leftBarButtonItem
    
    //create the complete and cancel buttons
    var baseFrame = inputToolbar!.contentView!.rightBarButtonItem!.frame
    var sideLength = min(baseFrame.height, baseFrame.width)
    completeButton = UIButton(frame: CGRectMake(baseFrame.origin.x, baseFrame.origin.y, sideLength, sideLength))
    completeButton?.setImage(UIImage(named: "Check_Mark"), forState: .Normal)
    completeButton?.setImage(UIImage(named: "Check_Mark"), forState: .Highlighted)
    
    baseFrame = inputToolbar!.contentView!.leftBarButtonContainerView!.frame
    sideLength = min(baseFrame.height, baseFrame.width)
    cancelButton = UIButton(frame: CGRectMake(baseFrame.origin.x, baseFrame.origin.y, sideLength, sideLength))
    cancelButton?.setImage(UIImage(named: "X"), forState: .Normal)
    cancelButton?.setImage(UIImage(named: "X"), forState: .Highlighted)
    
    //make the complete and cancel buttons the default
    inputToolbar?.contentView?.leftBarButtonItem = cancelButton
    inputToolbar?.contentView?.leftBarButtonItem?.enabled = true
    inputToolbar?.contentView?.rightBarButtonItem = completeButton
    inputToolbar?.contentView?.rightBarButtonItem?.enabled = true
    NSNotificationCenter.defaultCenter().addObserver(dataSource!, selector: "getChat", name: "NewChat", object: nil)
//    NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkForExchangeAndRefresh:", name: "NewChat", object: nil)
  }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.dataSource?.latestMessageDate != nil {
            self.dataSource?.getChatAfterDate((self.dataSource?.latestMessageDate)!)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.dataSource?.removeNoti()
    }
    
    func appDidBecomeActive() {
         if self.isViewLoaded() && self.view.window != nil {
            self.dataSource?.getChatAfterDate(NSDate(timeIntervalSince1970: 0 ))
        }
    }
    
//    func checkForExchangeAndRefresh(notification: NSNotification) {
//        if notification.userInfo != nil {
//            let userInfo : NSDictionary = notification.userInfo!
//            let exchangeRecordIDName = userInfo.valueForKey("exchangeRecordIDName") as! String
//            let context = NSManagedObjectContext.MR_context()
//            let exchangeFromOtherContext = Exchange.MR_findFirstByAttribute("recordIDName", withValue: exchangeRecordIDName, inContext: context)
//            if exchangeRecordIDName == exchangeFromOtherContext.valueForKey("recordIDName") as! String {
//                exchangeFromOtherContext.setValue(true, forKey: "isRead")
//                context.MR_saveToPersistentStoreAndWait()
//            }
//        }
//    }
    
  //MARK: - Required Subclassing Methods for Collection View and Layout
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    return super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
  }
  
  override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
    return kJSQMessagesCollectionViewCellLabelHeightDefault
  }
  
  override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
    return indexPath.item % 3 == 0 ? kJSQMessagesCollectionViewCellLabelHeightDefault : 0
  }
  
  override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
    return 0
  }
  
  //MARK: - Handling the Keyboard
    func keyboardWillShow(notification: NSNotification) {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        
    automaticallyScrollsToMostRecentMessage = true
    self.inputToolbar?.contentView?.leftBarButtonContainerView?.alpha = 0.0
    self.inputToolbar?.contentView?.rightBarButtonContainerView?.alpha = 0.0
    
    self.inputToolbar?.contentView?.leftBarButtonItem = nil//self.attachmentButton
    self.inputToolbar?.contentView?.rightBarButtonItem = self.sendButton
    self.inputToolbar?.contentView?.rightBarButtonItem?.enabled = !self.keyboardController!.textView!.text!.isEmpty
    
    self.dataSource?.scrollToBottom()
        
        
    UIView.animateWithDuration(0.5) {
      self.inputToolbar?.contentView?.leftBarButtonContainerView?.alpha = 1.0
      self.inputToolbar?.contentView?.rightBarButtonContainerView?.alpha = 1.0
    }
    
  }
  
    func keyboardWillHide(notification: NSNotification) {
     
    automaticallyScrollsToMostRecentMessage = false
    inputToolbar?.contentView?.leftBarButtonContainerView?.alpha = 0.0
    inputToolbar?.contentView?.rightBarButtonContainerView?.alpha = 0.0
    
    inputToolbar?.contentView?.leftBarButtonItem = cancelButton
    inputToolbar?.contentView?.rightBarButtonItem = completeButton
    inputToolbar?.contentView?.rightBarButtonItem?.enabled = true
        
    UIView.animateWithDuration(0.5, animations: {
      self.inputToolbar?.contentView?.leftBarButtonContainerView?.alpha = 1.0
      self.inputToolbar?.contentView?.rightBarButtonContainerView?.alpha = 1.0
      }) { (_) -> Void in
        self.automaticallyScrollsToMostRecentMessage = true
    }
  }
    
  //MARK: - Handling Camera
  var cameraNavController: TGCameraNavigationController?
    func presentImagePicker() {
     TGCamera.setOption(kTGCameraOptionHiddenFilterButton, value: NSNumber(bool: true))
    
    cameraNavController = TGCameraNavigationController.newWithCameraDelegate(self)
    presentViewController(cameraNavController!, animated: true) { }
  }
  
    func cameraDidCancel() {
     cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
    func cameraDidTakePhoto(image: UIImage!) {
     sendImage(image)
    cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
    func cameraDidSelectAlbumPhoto(image: UIImage!) {
     sendImage(image)
    cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
  //MARK: - Handling Buttons
    override func didPressAccessoryButton(sender: UIButton!) {
     switch sender {
    case cancelButton!:
      let alert = UIAlertController(title: "Cancel Exchange", message: "Are you sure that you want to cancel this exchange? This can not be undone!", preferredStyle: UIAlertControllerStyle.Alert)
      let doNotDelete = UIAlertAction(title: "Do Not Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
      let doDelete = UIAlertAction(title: "Cancel Exchange", style: UIAlertActionStyle.Destructive) { (alertAction) -> Void in
        self.delegate!.cancelExchange(self.exchange)
        self.navigationController!.popViewControllerAnimated(true)
      }
      alert.addAction(doNotDelete)
      alert.addAction(doDelete)
      self.presentViewController(alert, animated: true, completion: nil)
      break
    case attachmentButton!:
//      presentImagePicker()
      break
    default: break
    }
  }
  
  private func sendImage(image: UIImage) {
    //TODO: make the image appear
  }
  
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    switch button {
    case completeButton!:
        logw("CompleteButton")
      let alert = UIAlertController(title: "Confirm Exchange", message: "Congratulations on your successful exchange!", preferredStyle: UIAlertControllerStyle.Alert)
      let successfulExchange = UIAlertAction(title: "We've successfully exchanged.", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
        self.delegate!.completeExchange(self.exchange)
        self.navigationController!.popViewControllerAnimated(true)
      }
      let notExchangedYet = UIAlertAction(title: "We're not done yet!", style: UIAlertActionStyle.Cancel, handler: nil)
      alert.addAction(successfulExchange)
      alert.addAction(notExchangedYet)
      self.presentViewController(alert, animated: true, completion: nil)
      break
    case sendButton!:
        logw("SendButton")
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            break
        }
      JSQSystemSoundPlayer.jsq_playMessageSentSound()
      dataSource?.didPressSendButton(button, withMessageText: text, senderId: senderId, senderDisplayName: senderDisplayName, date: date)
      finishSendingMessageAnimated(true)
      break
    default: break
    }
  }
  
  override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
    //TODO: segue to user's profile page
  }
  
  //MARK: - Camera Data Methods
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
    picker.dismissViewControllerAnimated(true, completion: nil)
    
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
  
}
protocol ChatDeletionDelegate {
  func cancelExchange(exchange: NSManagedObject)
  func completeExchange(exchange: NSManagedObject)
}
