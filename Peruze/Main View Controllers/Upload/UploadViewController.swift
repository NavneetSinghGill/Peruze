//
//  UploadViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/23/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SystemConfiguration
import CloudKit
import SwiftLog

class UploadViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, TGCameraDelegate {
  
  private struct Constants {
    static let BufferSize: CGFloat = 8
    static let DefaultImage = UIImage(named: "Add_Photo")
    static let AlertTitle = "Not Enough Information"
    static let AlertMessage = "To increase your chances of an exchange, fill out the max amount of information!"
    static let descriptionTextViewTag = 10
  }
  //MARK: - Variables
  @IBOutlet weak var scrollView: UIScrollView!
  private var mainImageView: UIImageView!
  private var titleTextField: UITextField!
  private var descriptionLabel: UILabel!
  private var descriptionTextView: UITextView!
    private var gg: UIButton!
  private var uploadButton: UIButton!
  private var cancelButton: UIButton!
  private var keyboardOnScreen = false
  var image: UIImage?
  var itemTitle: String?
  var itemDescription: String?
    var recordIDName: String?
    var parentVC: UIViewController?
  //MARK: - View Controller Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.tintColor = .redColor()
    
    //setup done button
//    if navigationController != nil {
//      cancelButton.enabled = true
//      cancelButton.hidden = false
//    }
    
    //setup main image view
    mainImageView = UIImageView()
    
    //setup title text field
    titleTextField = UITextField()
    titleTextField.borderStyle = UITextBorderStyle.RoundedRect
    titleTextField.placeholder = "Title"
    titleTextField.autocapitalizationType = UITextAutocapitalizationType.Words
    titleTextField.delegate = self
    titleTextField.sizeToFit()
    titleTextField.addTarget(self, action: "textFieldEditingChanged:",
      forControlEvents: UIControlEvents.EditingChanged)
    
    //setup description label
    descriptionLabel = UILabel()
    descriptionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
    descriptionLabel.text = "Description:"
    descriptionLabel.sizeToFit()
    
    //setup description text view
    descriptionTextView = UITextView()
    descriptionTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    descriptionTextView.delegate = self
    descriptionTextView.tag = Constants.descriptionTextViewTag
    descriptionTextView.layer.borderWidth = 1
    descriptionTextView.layer.borderColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 0.8).CGColor
    descriptionTextView.layer.cornerRadius = 5
    
    cancelButton = UIButton()
    cancelButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
    cancelButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
    cancelButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
    cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
    cancelButton.sizeToFit()
    cancelButton.addTarget(self, action: "cancelButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
    cancelButton.enabled = true
    
    //setup upload button
    uploadButton = UIButton()
    uploadButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
    uploadButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
    uploadButton.titleLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
    if self.navigationController != nil{
        uploadButton.setTitle("Upload", forState: UIControlState.Normal)
    } else {
        uploadButton.setTitle("Done", forState: UIControlState.Normal)
    }
    uploadButton.sizeToFit()
    uploadButton.addTarget(self, action: "upload:", forControlEvents: UIControlEvents.TouchUpInside)
    uploadButton.enabled = false
    
    //setup camera
    TGCamera.setOption(kTGCameraOptionHiddenFilterButton, value: NSNumber(bool: true))
    TGCameraColor.setTintColor(UIColor.redColor())
    
    //Notification Center setup
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "endUpload", name: NotificationCenterKeys.UploadItemDidFinishSuccessfully, object: nil)
    
    //Gesture Recognizer setup
    let tap = UITapGestureRecognizer(target: self, action: "tap:")
    tap.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(tap)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    mainImageView.image = image ?? mainImageView.image
    titleTextField.text = itemTitle
    descriptionTextView.text = itemDescription
    
    postOnFaceBook()
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
        
    //Scroll view setup
    setupScrollView()
    let height = uploadButton.frame.maxY + Constants.BufferSize
    scrollView.contentSize = CGSizeMake(view.frame.width, height)
    
    //Main Image View Setup
    mainImageView.image = mainImageView.image ?? Constants.DefaultImage
  }
  
  //MARK: - Setup Scroll View
  func setupScrollView() {
    //Setup main image view
    let imageX = view.frame.minX + Constants.BufferSize
    let imageY = (navigationController != nil ? CGFloat(0) : UIApplication.sharedApplication().statusBarFrame.height) + Constants.BufferSize
    let imageSideLength = view.frame.width - 2 * Constants.BufferSize
    let imageFrame = CGRectMake(imageX, imageY, imageSideLength, imageSideLength)
    mainImageView.frame = imageFrame
    scrollView.addSubview(mainImageView)
    
    //Setup title text view
    let titleX = imageX
    let titleY = imageFrame.maxY + Constants.BufferSize
    let titleWidth = imageSideLength
    let titleHeight = titleTextField.frame.height
    let titleFrame = CGRectMake(titleX, titleY, titleWidth, titleHeight)
    titleTextField.frame = titleFrame
    scrollView.addSubview(titleTextField)
    
    //Setup description label
    let labelX = titleFrame.minX
    let labelY = titleFrame.maxY + Constants.BufferSize
    descriptionLabel.frame.origin = CGPointMake(labelX, labelY)
    scrollView.addSubview(descriptionLabel)
    
    //Setup description text view
    let descrX = labelX
    let descrY = descriptionLabel.frame.maxY + Constants.BufferSize
    let descrWidth = imageSideLength
    let bottomVisible = (tabBarController?.tabBar.frame.minY ?? view.frame.maxY) - 3 * Constants.BufferSize
    let descrHeight = max(bottomVisible - uploadButton.frame.height - descriptionLabel.frame.maxY, 100)
    let descrFrame = CGRectMake(descrX, descrY, descrWidth, descrHeight)
    descriptionTextView.frame = descrFrame
    scrollView.addSubview(descriptionTextView)
    
    //Setup upload button
    let uploadX = view.frame.width / 2 - uploadButton.frame.width / 2
    let uploadY = descrFrame.maxY + Constants.BufferSize
    uploadButton.frame.origin = CGPointMake(uploadX, uploadY)
    scrollView.addSubview(uploadButton)
    
    let cancelX = view.frame.width - cancelButton.frame.width - 16
    let cancelY = uploadButton.frame.origin.y
    cancelButton.frame.origin = CGPointMake(cancelX, cancelY)
    scrollView.addSubview(cancelButton)
  }
  
  //MARK: - Upload
  @IBAction func upload(sender: UIButton) {
    if !NetworkConnection.connectedToNetwork() {
      let alert = ErrorAlertFactory.alertForNetworkWithTryAgainBlock { self.upload(sender) }
      presentViewController(alert, animated: true, completion: nil)
      return
    }
    if mainImageView.image != Constants.DefaultImage && !titleTextField.text!.isEmpty {
      beginUpload()
      logw("OperationQueue().addOperation(PostItemOperation)")
      let allCompletionHandlers = { dispatch_async(dispatch_get_main_queue()) {
        if self.parentVC != nil && self.parentVC!.isKindOfClass(PeruseExchangeViewController){
//            let per = self.parentVC as! PeruseExchangeViewController
            NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruzeExchangeScreen", object: nil)
        }
        self.endUpload() } }
            OperationQueue().addOperation(
                PostItemOperation(
                    image: mainImageView.image!,
                    title: titleTextField.text!,
                    detail: descriptionTextView.text,
                    recordIDName: recordIDName,
                    presentationContext: self,
                    completionHandler: allCompletionHandlers,
                    errorCompletionHandler: allCompletionHandlers
                )
            )

    } else {
      let alert = UIAlertController(title: Constants.AlertTitle, message: Constants.AlertMessage, preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
    }
  }
  
  func cancelButtonTapped(sender: UIButton) {
    if navigationController == nil {
        dismissViewControllerAnimated(true, completion: nil)
    } else {
        self.mainImageView.image! = Constants.DefaultImage!
        self.titleTextField.text = ""
        self.descriptionLabel.text = ""
        self.tabBarController?.selectedIndex = 0
    }
  }
  
  //MARK: - Gesture Recognizers
  func tap(sender: UITapGestureRecognizer) {
    if keyboardOnScreen {
      view.endEditing(true)
    } else {
      let checkRect = view.convertRect(mainImageView.frame, toView: scrollView)
      if CGRectContainsPoint(checkRect, sender.locationInView(scrollView)) {
        presentImagePicker()
      }
    }
  }
  
  //MARK: - Image Picker Methods
  private var cameraNavController: TGCameraNavigationController?
  func presentImagePicker() {
    cameraNavController = TGCameraNavigationController.newWithCameraDelegate(self)
    presentViewController(cameraNavController!, animated: true) { }
  }
  
  func cameraDidCancel() {
    cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func cameraDidTakePhoto(image: UIImage!) { setImage(image) }
  
  func cameraDidSelectAlbumPhoto(image: UIImage!) { setImage(image) }
  
  private func setImage(image: UIImage) {
    mainImageView.image = image
    cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
    if !titleTextField.text!.isEmpty  && mainImageView.image != Constants.DefaultImage {
      uploadButton.enabled = true
    }
  }
  
  //MARK: - Handling Keyboard Display
  func keyboardWillShow(sender: NSNotification) {
    keyboardOnScreen = true
    if let userInfo = sender.userInfo {
      if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue {
        let top = navigationController?.navigationBar.frame.maxY ?? 0
        let bottom = keyboardFrame.height
        let insets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollView.scrollRectToVisible(uploadButton.frame, animated: true)
      }
    }
  }
  
  func keyboardWillHide(sender: AnyObject) {
    keyboardOnScreen = false
    UIView.animateWithDuration(0.5) {
      let top = self.navigationController?.navigationBar.frame.maxY ?? 0
      let bottom = self.tabBarController?.tabBar.frame.height ?? 0
      let insets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
      self.scrollView.contentInset = insets
      self.scrollView.scrollIndicatorInsets = insets
    }
  }
  
  //MARK: - UITextField and UITextView Delegate Methods
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if textField == titleTextField {
//      textField.endEditing(true)
      descriptionTextView.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return false
  }
  
  @IBAction func textFieldEditingChanged(sender: UITextField) {
    if !sender.text!.isEmpty  && mainImageView.image != Constants.DefaultImage {
      uploadButton.enabled = true
    }
  }
    
    func textViewDidChange(textView: UITextView) {
        if !titleTextField.text!.isEmpty  && mainImageView.image != Constants.DefaultImage && textView.tag
         == Constants.descriptionTextViewTag{
            uploadButton.enabled = true
        }
    }
  
  //MARK: - Upload View
  var uploadingView: UploadingEyesView?
  private func beginUpload() {
    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    let uploadingX = navigationController?.navigationBar.frame.minX ?? 0
    let uploadingY = navigationController?.navigationBar.frame.maxY ?? 0
    let uploadingWidth = view.frame.width
    let bottomOfView = tabBarController?.tabBar.frame.minY ?? view.frame.maxY
    let uploadingHeight = bottomOfView - uploadingY
    let uploadingFrame = CGRectMake(uploadingX, uploadingY, uploadingWidth, uploadingHeight)
    uploadingView = UploadingEyesView(frame: uploadingFrame)
    view.addSubview(uploadingView!)
    uploadingView!.beginUpload()
  }
  
  func endUpload() {
    mainImageView.image = Constants.DefaultImage
    titleTextField.text = ""
    descriptionTextView.text = ""
    uploadingView?.endUpload() {
      UIApplication.sharedApplication().endIgnoringInteractionEvents()
      self.uploadingView?.removeFromSuperview()
      if self.navigationController == nil {
        self.dismissViewControllerAnimated(true, completion: nil)
      }
      self.tabBarController?.selectedIndex = 0
    }
  }
    
    //MARK: - Post On facebook
    func postOnFaceBook() {
        if !FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions") {
            let manager = FBSDKLoginManager()
            manager.logInWithPublishPermissions(["publish_actions"], handler: { (loginResult, error) -> Void in
                if !loginResult.grantedPermissions.contains("publish_actions") {
                    self.performPost()
                }
            })
        } else {
            performPost()
        }
    }
    
    
    func performPost() {
//        let image : UIImage = UIImage(named: "Check_Mark")!
        let request = FBSDKGraphRequest(graphPath: "me/feed", parameters:["message" : "hello world!", "link" : "www.google.com","picture": "Check_Mark.png","caption":"Build great social apps and get more installs.","description":"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.", "tags":""],  HTTPMethod:"POST")
        request.startWithCompletionHandler({ (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            //set error and return
            if error != nil {
                print("Post failed: \(error)")
            } else {
                print("Post success")
            }
            
        })
        
    }
    
}
