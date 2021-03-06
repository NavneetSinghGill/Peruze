//
//  ProfileSetupSelectPhotoViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 5/26/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

///whether or not verbose print statements should be called for each function
private let logging = true

class ProfileSetupSelectPhotoViewController: UIViewController, FacebookProfilePictureRetrievalDelegate {
  //MARK: - Variables
  private struct Constants {
    static let NumberOfProfilePictures = 4
    static let ChooseAPhotoFadeDuration: NSTimeInterval = 1.0
    static let LoadingLabelText = ""
    static let BufferSize: CGFloat = 8
    static let ImageStrokeWidth: CGFloat = 2
    static let SegueIdentifier = "toSelectRange"
    //errors
    static let NotEnoughProfilePicturesTitle = "Profile Photos"
    static let NotEnoughProfilePicturesMessage = "Oops! It looks like there was a problem fetching your profile photos. Please cancel and try again."
    static let NotEnoughProfilePicturesCancelButton = "Okay"
    static let HitNextWithoutImageTitle = "No Profile Picture"
    static let HitNextWithoutImageMessage = "Please choose a profile photo before you go."
    static let HitNextWithoutImageCancelButton = "Okay"
  }
  
  //MARK: Outlets
  @IBOutlet weak var chooseLabel: UILabel!
  @IBOutlet weak var aPhotoLabel: UILabel!
  @IBOutlet weak var upperLeft: CircleImage!
  @IBOutlet weak var upperRight: CircleImage!
  @IBOutlet weak var lowerRight: CircleImage!
  @IBOutlet weak var lowerLeft: CircleImage!
  @IBOutlet weak var center: CircleImage!
  //MARK: Local Vars
  private var facebookData = FacebookDataSource()
    var percentLoaded: Int?
    var profileImageUrls: [String]?{
        didSet {
            if profileImageUrls?.count == Constants.NumberOfProfilePictures {
                setupImageViews()
            }
        }
    }
  var profileImages: [UIImage]? {
    didSet {
      setupImageViews()
    }
  }
  private var loadingCircle: LoadingCircleView?
    private var loadingLabel = UILabel()
  
  //MARK: - View Controller Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController!.navigationBar.tintColor = UIColor.redColor()
    setupLoadingViews()
    facebookData.profilePictureRetrievalDelegate = self
    facebookData.getProfilePhotosWithCompletion { [unowned self] (success, error) -> Void in
      if !success {
        logw("ProfileSetupSlectPhotoViewController getProfilePhotosWithCompletion failed with error: \(error)")
        self.profilePictureFetchingError()
      }
      dispatch_async(dispatch_get_main_queue()) {
        self.loadingCircle?.stop()
      }
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if center.image == nil {
      loadingCircle?.start()
      loadingCircle?.backgroundColor = .clearColor()
    }
  }
  
  //MARK: - Setup and Animations
  private func setupLoadingViews() {
    loadingCircle = LoadingCircleView()
    loadingCircle!.bounds = center.bounds
    loadingCircle!.center = CGPointMake(view.bounds.width / 2, view.bounds.height / 2)
    loadingLabel.text = Constants.LoadingLabelText
    loadingLabel.font = .preferredFontForTextStyle(UIFontTextStyleBody)
    loadingLabel.textAlignment = .Center
    loadingLabel.bounds = loadingCircle!.bounds
    loadingLabel.center = loadingCircle!.center
    view.addSubview(loadingCircle!)
    view.addSubview(loadingLabel)
  }
  
  private func setupImageViews() {
    var views = [upperLeft, upperRight, lowerLeft, lowerRight]
    for index in 0..<Constants.NumberOfProfilePictures {
      views[index].hidden = false
      views[index].strokeWidth = Constants.ImageStrokeWidth
      if profileImages!.count > index {
        views[index].image = profileImages![index]
      }
    }
    
    if profileImages != nil && profileImages!.count != 0 && profileImageUrls != nil {
        if let urlLastComponent = NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kCurrentProfilePicUrl) as? String {
            for urlString in profileImageUrls! {
                if urlLastComponent as! String == lastComponentOfString(urlString, char: "/") {
                    let index = profileImageUrls?.indexOf(urlString)
                    if index == 0 {
                        self.tap(upperLeft)
                    } else if index == 1 {
                        self.tap(upperRight)
                    } else if index == 2 {
                        self.tap(lowerLeft)
                    } else if index == 3 {
                        self.tap(lowerRight)
                    }
                }
            }
        } else {
            self.tap(upperLeft)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![0], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    center.hidden = false
    center.alpha = 0.0
    self.tap(upperLeft)
    bringInProfilePhotos()
  }
  
  private func bringInProfilePhotos() {
    chooseLabel.hidden = false
    aPhotoLabel.hidden = false
    
    //translate photos off screen
    let (transULX, transULY): (CGFloat, CGFloat) = (-view.frame.width, upperLeft.frame.height)
    let (transURX, transURY): (CGFloat, CGFloat) = (view.frame.height, -view.frame.width / 2)
    let (transLLX, transLLY): (CGFloat, CGFloat) = (-view.frame.width, view.frame.height * 2)
    let (transLRX, transLRY): (CGFloat, CGFloat) = (view.frame.width, view.frame.width)
    upperLeft.transform = CGAffineTransformMakeTranslation(transULX, transULY)
    upperRight.transform = CGAffineTransformMakeTranslation(transURX, transURY)
    lowerLeft.transform = CGAffineTransformMakeTranslation(transLLX, transLLY)
    lowerRight.transform = CGAffineTransformMakeTranslation(transLRX, transLRY)
    
    UIView.animateWithDuration(Constants.ChooseAPhotoFadeDuration, delay: 0.5, options: .CurveEaseOut, animations: { () -> Void in
      //set alphas
      self.chooseLabel.alpha = 1.0
      self.aPhotoLabel.alpha = 1.0
      self.center.alpha = 1.0
      
      //put images back in their place
      self.upperLeft.transform = CGAffineTransformMakeTranslation(-1/transULX, -1/transULY)
      self.upperRight.transform = CGAffineTransformMakeTranslation(-1/transURX, -1/transURY)
      self.lowerLeft.transform = CGAffineTransformMakeTranslation(-1/transLLX, -1/transLLY)
      self.lowerRight.transform = CGAffineTransformMakeTranslation(-1/transLRX, -1/transLRY)
      }, completion: nil)
  }
  
  //MARK: - Actions
  @IBAction func cancel(sender: UIBarButtonItem) {
    FBSDKLoginManager().logOut()
    dismissViewControllerAnimated(true){
      self.operationQueue.cancelAllOperations()
    }
  }
  
  private var nextBlurView: UIVisualEffectView!
  private let operationQueue = OperationQueue()
  @IBAction func next(sender: UIButton) {
    //setup next loading views and disable interaction
    sender.userInteractionEnabled = false
    nextLoadingSetup()
    
    //setup operation queue
    //operationQueue.qualityOfService = NSQualityOfService.UserInteractive
    
    //upload facebook profile info and fetch user info from the cloud
    let getFacebookProfileOp = FetchFacebookUserProfile(presentationContext: self)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let postFacebookInfoToServer = PostUserOperation(presentationContext: self, database: publicDB)
    
    //saves the user's image to the local database
    let saveImageOp = NSBlockOperation {
        if logging { logw("saveImageOp called.  ") }
        if let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext) {
            let imageData = UIImagePNGRepresentation(self.center.image!)
            me.setValue(imageData, forKey: "image")
            NSUserDefaults.standardUserDefaults().setValue(imageData, forKey: "tempImage")
            NSUserDefaults.standardUserDefaults().synchronize()
            managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        }
    }
    saveImageOp.completionBlock = {
      logw("saveImageOp.completionBlock ")
    }
    
    //operation that performs the segue to the next VC
    let performSegueOp = NSBlockOperation {
      if logging { logw("performSeugeOp called.  ") }
      dispatch_async(dispatch_get_main_queue()) {
        self.nextLoadingTearDown()
        sender.userInteractionEnabled = true
        self.performSegueWithIdentifier(Constants.SegueIdentifier, sender: self)
      }
    }
    //add dependencies
    postFacebookInfoToServer.addDependencies([getFacebookProfileOp, saveImageOp])
    performSegueOp.addDependencies([getFacebookProfileOp, postFacebookInfoToServer, saveImageOp])
    operationQueue.addOperations([getFacebookProfileOp, postFacebookInfoToServer, saveImageOp, performSegueOp], waitUntilFinished: false)
  }
  
  
  private func nextLoadingSetup() {
    //setup the loading blur effect
    loadingCircle?.start()
    let blur = UIBlurEffect(style: UIBlurEffectStyle.Light)
    nextBlurView = UIVisualEffectView(effect: blur)
    nextBlurView.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
    nextBlurView.alpha = 0.0
    view.insertSubview(nextBlurView, aboveSubview: center)
    UIView.animateWithDuration(0.5) {
      self.nextBlurView.alpha = 1.0
    }
    //start the network indicator and disable user interaction
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    self.view.userInteractionEnabled = false
  }
  
  private func nextLoadingTearDown() {
    self.view.userInteractionEnabled = true
    self.loadingCircle?.stop()
    UIView.animateWithDuration(0.5, animations: { self.nextBlurView.alpha = 0.0 }, completion: { (_) -> Void in
      self.nextBlurView.removeFromSuperview()
    })
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
  }
  
  //MARK: - Errors
  private func handleError(error: NSError?, handler:(Void -> Void)? = nil) {
    dispatch_async(dispatch_get_main_queue()){
      if error != nil {
        logw(error!.localizedDescription)
        let alert = ErrorAlertFactory.alertFromError(error!)
        self.presentViewController(alert, animated: true, completion: nil)
        self.view.userInteractionEnabled = true
        self.loadingCircle?.stop()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        handler?()
      }
    }
  }
  private func profilePictureFetchingError() {
    let notEnoughProfilePicturesAlertView = UIAlertView(title: Constants.NotEnoughProfilePicturesTitle,
      message: Constants.NotEnoughProfilePicturesMessage,
      delegate: nil,
      cancelButtonTitle: Constants.NotEnoughProfilePicturesCancelButton)
    notEnoughProfilePicturesAlertView.show()
    for view in [center, upperLeft, upperRight, lowerLeft, lowerRight] { view.hidden = true }
  }
  
  //MARK: - Gesture Handling
  @IBAction func tapUpperLeft(sender: UITapGestureRecognizer) {
    if UIImagePNGRepresentation(upperLeft.image!) != nil {
        tap(upperLeft)
        NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![0], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
  }
    @IBAction func tapLowerLeft(sender: UITapGestureRecognizer) {
        if UIImagePNGRepresentation(lowerLeft.image!) != nil {
            tap(lowerLeft)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![2], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
  }
    @IBAction func tapUpperRight(sender: UITapGestureRecognizer) {
        if UIImagePNGRepresentation(upperRight.image!) != nil {
            tap(upperRight)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![1], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
  }
    @IBAction func tapLowerRight(sender: UITapGestureRecognizer) {
        if UIImagePNGRepresentation(lowerRight.image!) != nil {
            tap(lowerRight)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![3], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
  }
  private func tap(selectedImage: CircleImage) {
    for obj in [upperLeft, upperRight, lowerRight, lowerLeft] { obj.selected = false }
    selectedImage.selected = true
    center.image = selectedImage.image
  }
    
    func lastComponentOfString(source:String, char: String) -> String {
        let reverseSoruce = String(source.characters.reverse())
        if let range = reverseSoruce.rangeOfString(char){
            return source.substringFromIndex(range.endIndex)
        } else {
            return ""
        }
    }
    
  //MARK: - Navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    //success
    if let destVC = segue.destinationViewController as? ProfileSetupRangeViewController {
      if self.center.image != nil {
        destVC.profileImage = self.center.image
      } else {
        assertionFailure("The image passed to the ProfileSetupRangeViewController is nil")
      }
    }
  }
  override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
    if center.image == nil || loadingCircle != nil {
      let hitNextWithoutImageAlertView = UIAlertView(title: Constants.HitNextWithoutImageTitle, message: Constants.HitNextWithoutImageMessage, delegate: nil, cancelButtonTitle: Constants.HitNextWithoutImageCancelButton)
      hitNextWithoutImageAlertView.show()
      return false
    }
    return true
  }
  
}
