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
    var shouldShowUploadButton = false
    var wasMainImageChanged: Bool!
    var imageUrl: String!
    var timer : NSTimer? = nil
    
    var newUploadedItemTitle = ""
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
        if self.navigationController != nil || shouldShowUploadButton == true {
            uploadButton.setTitle("Upload", forState: UIControlState.Normal)
        } else {
            uploadButton.setTitle("Edit", forState: UIControlState.Normal)
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
        wasMainImageChanged = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mainImageView.image = image ?? mainImageView.image
        titleTextField.text = itemTitle
        descriptionTextView.text = itemDescription
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
            if uploadButton.titleLabel?.text == "Upload"{
                beginUpload()
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(200, target: self, selector: nil, userInfo: nil, repeats: true)
            if wasMainImageChanged == true {
                logw("UploadViewController Image Upload to s3 started at time: \(self.timer?.timeInterval)")
                let uniqueImageName = createUniqueName()
                let uploadRequest = Model.sharedInstance().uploadRequestForImageWithKey(uniqueImageName, andImage: mainImageView.image!)
                let transferManager = AWSS3TransferManager.defaultS3TransferManager()
                transferManager.upload(uploadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {task in
                    if task.error != nil {
                        logw("UploadViewController s3 item image upload failed at time: \(self.timeIntervalSince((self.timer?.fireDate)!)) with error: \(task.error)")
                        
                        UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        self.uploadingView?.removeFromSuperview()
                        if self.navigationController == nil {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                        
                        let alert = UIAlertController(title: "Peruze", message: "An error occured while uploading your item.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        
                    }
                    if task.result != nil {
                        self.uploadToCloud(uniqueImageName)
                    }
                    return nil
                })
            } else {
                uploadToCloud(self.imageUrl)
            }
        } else {
            let alert = UIAlertController(title: Constants.AlertTitle, message: Constants.AlertMessage, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func uploadToCloud(uniqueImageName: String) {
        //                    let uploadOutput = task.result
        logw("UploadViewController upload item to cloud started at time: \(self.timeIntervalSince((self.timer?.fireDate)!))")
        logw("OperationQueue().addOperation(PostItemOperation)")
        let successCompletionHandler = {
            logw("UploadViewController upload item to cloud success at time: \(self.timeIntervalSince((self.timer?.fireDate)!))")
            self.wasMainImageChanged = false
            if self.parentVC != nil && self.parentVC!.isKindOfClass(PeruseExchangeViewController){
                //            let per = self.parentVC as! PeruseExchangeViewController
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruzeExchangeScreen", object: nil)
            }
            if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPostingToFacebookOn) == nil ||
                NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPostingToFacebookOn) as! String == "yes" {
                    self.postOnFaceBook(uniqueImageName)
            }
            if self.uploadButton.titleLabel?.text == "Upload" {
                self.endUpload()
            }
        }
        let failureCompletionHandler = {
            logw("UploadViewController upload item to cloud failed at time: \(self.timeIntervalSince((self.timer?.fireDate)!))")
            if self.parentVC != nil && self.parentVC!.isKindOfClass(PeruseExchangeViewController){
                //            let per = self.parentVC as! PeruseExchangeViewController
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruzeExchangeScreen", object: nil)
            }
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while Editing item.", preferredStyle: .Alert)
            
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            if self.uploadButton.titleLabel?.text == "Upload" {
                self.endUpload()
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        OperationQueue().addOperation(
            PostItemOperation(
                image: self.mainImageView.image!,
                title: self.titleTextField.text!,
                detail: self.descriptionTextView.text,
                recordIDName: self.recordIDName,
                imageUrl: uniqueImageName,
                presentationContext: self,
                completionHandler: successCompletionHandler,
                errorCompletionHandler: failureCompletionHandler
            )
        )
    }
    
    func timeIntervalSince(fromDate: NSDate) -> NSTimeInterval{
        return fromDate.timeIntervalSinceDate(NSDate())
    }
    
    func cancelButtonTapped(sender: UIButton) {
        if navigationController == nil {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.mainImageView.image! = Constants.DefaultImage!
            self.image = Constants.DefaultImage!
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
    
    private func setImage(image1: UIImage) {
        wasMainImageChanged = true
        mainImageView.image = image1
        self.image = image1
        cameraNavController!.dismissViewControllerAnimated(true, completion: nil)
        if !titleTextField.text!.isEmpty  && mainImageView.image != Constants.DefaultImage {
            uploadButton.enabled = true
            if uploadButton.titleLabel?.text == "Edit" {
                uploadButton.setTitle("Done", forState: UIControlState.Normal)
                uploadButton.sizeToFit()
            }
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
        if uploadButton.titleLabel?.text == "Edit" {
            uploadButton.setTitle("Done", forState: UIControlState.Normal)
            uploadButton.sizeToFit()
        }
        if !sender.text!.isEmpty  && mainImageView.image != Constants.DefaultImage {
            uploadButton.enabled = true
        } else {
            uploadButton.enabled = false
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if uploadButton.titleLabel?.text == "Edit" {
            uploadButton.setTitle("Done", forState: UIControlState.Normal)
            uploadButton.sizeToFit()
        }
        if !titleTextField.text!.isEmpty  && mainImageView.image != Constants.DefaultImage && textView.tag
            == Constants.descriptionTextViewTag{
                uploadButton.enabled = true
        } else {
            uploadButton.enabled = false
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
        dispatch_async(dispatch_get_main_queue()) {
            self.mainImageView.image = Constants.DefaultImage
            self.image = Constants.DefaultImage
            self.titleTextField.text = ""
            self.descriptionTextView.text = ""
            self.uploadingView?.endUpload() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                self.uploadingView?.removeFromSuperview()
                if self.navigationController == nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                self.tabBarController?.selectedIndex = 0
            }
        }
    }
    
    //MARK: - Post On facebook
    func postOnFaceBook(uniqueImageName: String) {
        if !FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions") {
            let manager = FBSDKLoginManager()
            manager.logInWithPublishPermissions(["publish_actions"], handler: { (loginResult, error) -> Void in
                if !loginResult.grantedPermissions.contains("publish_actions") {
                    self.performPost(uniqueImageName)
                }
            })
        } else {
            performPost(uniqueImageName)
        }
    }
    
    
    func performPost(uniqueImageName: String) {
        
        
        let params: NSMutableDictionary = [:]
        params.setValue("1", forKey: "setdebug")
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        params.setValue((me.valueForKey("firstName") as! String) + " " + (me.valueForKey("lastName") as! String) , forKey: "senderId")
        params.setValue("facebook", forKey: "shareType")
        params.setValue(self.titleTextField.text!, forKey: "recordID")
        //        params[@"shareIds"] = self.eventsIdsString;
        let title = self.titleTextField.text!
        Branch.getInstance().getShortURLWithParams(params as [NSObject : AnyObject], andCallback: { (url: String!, error: NSError!) -> Void in
            if (error == nil) {
                // Now we can do something with the URL...
                logw("url: \(url)")
                let urlString = "\(url)"
                let request = FBSDKGraphRequest(graphPath: "me/feed", parameters:["message" : "New Peruze item \'\(title)\'", "link" :urlString,"picture": s3Url(uniqueImageName),"caption":"Change how you exchange","description":self.descriptionTextView.text!, "tags":""],  HTTPMethod:"POST")
                request.startWithCompletionHandler({ (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                    //set error and return
                    if error != nil {
                        print("Upload item on FB Post failed: \(error)")
                    } else {
                        print("Upload item on FB Post success")
                    }
                })
            }
            
        })
    }
    
}
