//
//  SettingsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 7/1/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CoreLocation
import MessageUI
import SwiftLog

class SettingsViewController: UITableViewController, FacebookProfilePictureRetrievalDelegate ,MFMailComposeViewControllerDelegate{
  
  private struct Constants {
    static let NumberOfProfilePictures = 4
    static let ChooseAPhotoFadeDuration: NSTimeInterval = 1.0
    static let LoadSpeed: NSTimeInterval = 0.5
    static let LoadFadeDuration: NSTimeInterval = 0.0
    static let BufferSize: CGFloat = 8
    static let ImageStrokeWidth: CGFloat = 2
    static let AboutIndexPath = NSIndexPath(forRow: 2, inSection: 2)
    static let DeveloperIndexPath = NSIndexPath(forRow: 3, inSection: 2)
    static let AboutURL = NSURL(string: "http://www.perusenow.com")
    static let DeveloperWebsiteURL = NSURL(string: "http://www.philliphtrentiii.info")
    static let friendsNavigationSegueIdentifier = "toFriendsNavigationSegueIdentifier"
    struct Alerts {
      struct ProfilePhoto {
        static let Title = "Profile Photos"
        static let Message = "Oops! It looks like there was a problem fetching your profile photos. Please cancel and try again."
        static let CancelButton = "Okay"
      }
      struct LogOutOfFacebook {
        static let Title = "Profile Photos"
        static let Message = "Oops! It looks like there was a problem fetching your profile photos. Please cancel and try again."
        static let CancelButton = "Okay"
      }
      struct DeleteAccount {
        static let Title = "Profile Photos"
        static let Message = "Oops! It looks like there was a problem fetching your profile photos. Please cancel and try again."
        static let CancelButton = "Okay"
      }
    }
  }
  
  //MARK: - Variables
  @IBOutlet weak var upperLeft: CircleImage!
  @IBOutlet weak var upperRight: CircleImage!
  @IBOutlet weak var lowerRight: CircleImage!
  @IBOutlet weak var lowerLeft: CircleImage!
  @IBOutlet weak var loadingViewContainer: UIView!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var inviteFacebookFriendsButton: UIButton!
    @IBOutlet weak var pushNotificationSwitch: UISwitch!
    @IBOutlet weak var kIsPostingToFacebookOn: UISwitch!
  //MARK: Local Vars
  private var facebookData = FacebookDataSource()
  private var locationManager = CLLocationManager()
    var percentLoaded: Int?
    var profileImageUrls: [String]?{
        didSet {
//            if profileImageUrls?.count == Constants.NumberOfProfilePictures {
                setupImageViews()
//            }
        }
    }
  var profileImages: [UIImage]? {
    didSet {
      setupImageViews()
    }
  }
    var initialFriendFilterValue : Float = 0.0
    var initialRangeFilterValue : Float = 0.0
    
    private var selectedCircleImage: CircleImage!
    private var profilePicDidChange: Bool!
    private var loadingCircle: LoadingCircleView?
    var savedImageUrl: String?
    var shouldUpdateProfilePic = false
  
  //MARK: - View Controller Lifecycle
  override func viewDidLoad() {
    //distance
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    distanceValues.sortInPlace(<)
    distanceSlider.minimumValue = distanceValues.first!
    distanceSlider.maximumValue = distanceValues.last!
    distanceSlider.value = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UsersDistancePreference) as? Float ?? distanceSlider.maximumValue
    initialRangeFilterValue = distanceSlider.value
    
    //friends
    friendsValues.sortInPlace(<)
    friendsSlider.minimumValue = friendsValues.first!
    friendsSlider.maximumValue = friendsValues.last!
    friendsSlider.value = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UsersFriendsPreference) as? Float ?? friendsSlider.maximumValue
    initialFriendFilterValue = friendsSlider.value
 
    if distanceSlider.value == distanceSlider.maximumValue{
        rangeLabel.text = "Everywhere"
    } else {
        rangeLabel.text = "\(Int(distanceSlider.value)) mi"
    }
    
    //version
    let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    versionLabel.text = "Version " + version
    if selectedCircleImage == nil{
        selectedCircleImage = upperLeft
    }
    
    if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) as? String == "yes" {
        self.pushNotificationSwitch.on = true
    } else {
        self.pushNotificationSwitch.on = false
    }
    
    if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPostingToFacebookOn) as? String == "yes" {
        self.kIsPostingToFacebookOn.on = true
    } else {
        self.kIsPostingToFacebookOn.on = false
    }
  }
  
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(UniversalConstants.kIsPushNotificationOn) == nil ||
           defaults.valueForKey(UniversalConstants.kIsPushNotificationOn) as! String == "yes" {
            self.pushNotificationSwitch.on = true
        } else {
            self.pushNotificationSwitch.on = false
        }
        
        if defaults.valueForKey(UniversalConstants.kIsPostingToFacebookOn) == nil ||
            defaults.valueForKey(UniversalConstants.kIsPostingToFacebookOn) as! String == "yes" {
                self.kIsPostingToFacebookOn.on = true
        } else {
            self.kIsPostingToFacebookOn.on = false
        }
        
        if let urlLastComponent = NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kCurrentProfilePicUrl) as? String{
            savedImageUrl = urlLastComponent
        } else {
            savedImageUrl = ""
        }
    }
    
  override func viewDidAppear(animated: Bool) {
    super.viewWillAppear(animated)
    super.viewDidLoad()
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    facebookData.profilePictureRetrievalDelegate = self
    facebookData.getProfilePhotosWithCompletion { [unowned self] (success, error) -> Void in
        if !success {
            logw("\(error)")
            self.profilePictureFetchingError()
        }
        self.loadingCircle?.stop()
    }
    if loadingCircle == nil {
      setupLoadingViews()
    }
    if profileImages == nil || profileImages?.count == 0 {
      if !loadingCircle!.animating {
        loadingCircle?.start()
      }
    }
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if loadingCircle == nil {
      setupLoadingViews()
      
    }
    if profileImages == nil || profileImages?.count == 0 {
      if !loadingCircle!.animating {
        loadingCircle?.start()
      }
    }
  }
  //MARK: - Setup
    private func setupLoadingViews() {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let loadingX: CGFloat = 0
    let loadingY: CGFloat = 0
    let loadingSideLength = min(loadingViewContainer.frame.width, loadingViewContainer.frame.height)
    loadingCircle = LoadingCircleView(frame: CGRectMake(loadingX, loadingY, loadingSideLength, loadingSideLength))
    loadingCircle!.backgroundColor = .clearColor()
    loadingCircle!.fullRotationCompletionDuration = Constants.LoadSpeed
    loadingCircle!.fadeOutAnimationDuration = Constants.LoadFadeDuration
    loadingViewContainer.addSubview(loadingCircle!)
  }
    
    func lastComponentOfString(source:String, char: String) -> String {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let reverseSoruce = String(source.characters.reverse())
        if let range = reverseSoruce.rangeOfString(char){
            return source.substringFromIndex(range.endIndex)
        } else {
            return ""
        }
    }
    
    private func setupImageViews() {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    var views = [upperLeft, upperRight, lowerLeft, lowerRight]
    for index in 0..<Constants.NumberOfProfilePictures {
      views[index].hidden = false
      views[index].strokeWidth = Constants.ImageStrokeWidth
      if profileImages!.count > index {
        views[index].image = profileImages![index]
      }
    }

        if profileImages != nil && profileImages!.count != 0 && profileImageUrls != nil {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if let urlLastComponent = NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kCurrentProfilePicUrl) as? String {
            for urlString in profileImageUrls! {
                if urlLastComponent == lastComponentOfString(urlString, char: "/") {
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
            if profileImageUrls != nil && profileImageUrls?.count != 0{
                NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![0], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
  }
  
  //MARK: - Errors and Alerts
    private func profilePictureFetchingError() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let notEnoughProfilePicturesAlertView = UIAlertView(title: Constants.Alerts.ProfilePhoto.Title,
      message: Constants.Alerts.ProfilePhoto.Message,
      delegate: nil,
      cancelButtonTitle: Constants.Alerts.ProfilePhoto.CancelButton)
    notEnoughProfilePicturesAlertView.show()
    for view in [upperLeft, upperRight, lowerLeft, lowerRight] { view.hidden = true }
  }
  
    private func logOutOfFacebookAlertWithCompletion(completion: (Bool -> Void)) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    //TODO: you're about to log out of facebook
    completion(true)
  }
  
    private func deleteAccountAlertWithCompletion(completion: (Bool -> Void)) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    //TODO: you're about to permanently delete everything
    completion(true)
  }
  
  //MARK: - Gesture Handling
    @IBAction func tapUpperLeft(sender: UITapGestureRecognizer) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    if UIImagePNGRepresentation(upperLeft.image!) != nil {
        tap(upperLeft)
        NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![0], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
        NSUserDefaults.standardUserDefaults().synchronize()
        shouldUpdateProfilePic = lastComponentOfString(profileImageUrls![0], char: "/") == savedImageUrl ? false: true
    }
  }
    @IBAction func tapLowerLeft(sender: UITapGestureRecognizer) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if UIImagePNGRepresentation(lowerLeft.image!) != nil {
            tap(lowerLeft)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![2], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
            shouldUpdateProfilePic = lastComponentOfString(profileImageUrls![2], char: "/") == savedImageUrl ? false: true
        }
  }
    @IBAction func tapUpperRight(sender: UITapGestureRecognizer) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if UIImagePNGRepresentation(upperRight.image!) != nil {
            tap(upperRight)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![1], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
            shouldUpdateProfilePic = lastComponentOfString(profileImageUrls![1], char: "/") == savedImageUrl ? false: true
        }
  }
    @IBAction func tapLowerRight(sender: UITapGestureRecognizer) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if UIImagePNGRepresentation(lowerRight.image!) != nil {
            tap(lowerRight)
            NSUserDefaults.standardUserDefaults().setValue(lastComponentOfString(profileImageUrls![3], char: "/"), forKey: UniversalConstants.kCurrentProfilePicUrl)
            NSUserDefaults.standardUserDefaults().synchronize()
            shouldUpdateProfilePic = lastComponentOfString(profileImageUrls![3], char: "/") == savedImageUrl ? false: true
        }
  }
    
    private func tap(selectedImage: CircleImage) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    for obj in [upperLeft, upperRight, lowerRight, lowerLeft] { obj.selected = false }
    selectedImage.selected = true
    profilePicUpdate(selectedImage)
  }
    
    func profilePicUpdate(selectedImage: CircleImage){
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
            selectedCircleImage = selectedImage
    }
    
  //MARK: - Handling Buttons
    @IBAction func logOutOfFacebook(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    FBSDKAccessToken.setCurrentAccessToken(nil)
    FBSDKLoginManager().logOut()
    Model.sharedInstance().deleteAllSubscription()
    NSUserDefaults.standardUserDefaults().setValue(true, forKey: UniversalConstants.kSetSubscriptions)
    NSUserDefaults.standardUserDefaults().synchronize()
    logw("Logged out of account.")
    dismissViewControllerAnimated(false, completion: nil)
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "showIniticiaViewController", object: nil, userInfo: nil))
  }
  
    @IBAction func deleteProfile(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
//    FBSDKAccessToken.setCurrentAccessToken(nil)
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    me.setValue(1, forKey: "isDelete")
    let modifyUserOperation = UpdateUserOperation(personToUpdate: (me)){
        logw("Profile deleted.")
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: UserDefaultsKeys.ProfileHasActiveProfileKey)
        self.logOutOfFacebook(UIButton())
    }
      OperationQueue().addOperation(modifyUserOperation)
  }
  
    @IBAction func done(sender: UIBarButtonItem) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways && distanceSlider.value != distanceSlider.maximumValue {
      showMustChangeLocationSettingAlert()
    } else if !FBSDKAccessToken.currentAccessToken().hasGranted("user_friends") && friendsSlider.value != friendsSlider.maximumValue {
      mustChangeFacebookFriendsAccessSetting()
    } else {
        if initialRangeFilterValue != distanceSlider.value || initialFriendFilterValue != friendsSlider.value {
             NSNotificationCenter.defaultCenter().postNotification(NSNotification(name:"LNUpdateItemsOnFilterChange", object: nil, userInfo: nil))
        }
        
      NSUserDefaults.standardUserDefaults().setObject(Int(distanceSlider.value), forKey: UserDefaultsKeys.UsersDistancePreference)
      NSUserDefaults.standardUserDefaults().setObject(Int(friendsSlider.value), forKey: UserDefaultsKeys.UsersFriendsPreference)
            //Update profile Pic
        if shouldUpdateProfilePic == true {
            let dict:[String:AnyObject] = ["circleImage":selectedCircleImage]
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "profileUpdate", object: nil, userInfo: dict))
        }
      dismissViewControllerAnimated(true) {
        //Model.sharedInstance().fetchItemsWithinRangeAndPrivacy()
        //TODO: Pass edited data back to dataSource
      }
    }
  }
  
    @IBAction func inviteFacebookFriendsButtonTapped(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        performSegueWithIdentifier(Constants.friendsNavigationSegueIdentifier, sender: self)
    }
    
    @IBAction func sendLogs(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        sendReportWithAttachment()
    }

    @IBAction func pushNotificationSwitchTapped(sender: UISwitch) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let defaults = NSUserDefaults.standardUserDefaults()
        if sender.on == false {
            defaults.setValue("no", forKey: UniversalConstants.kIsPushNotificationOn)
            defaults.synchronize()
            
        } else {
            defaults.setValue("yes", forKey: UniversalConstants.kIsPushNotificationOn)
            defaults.synchronize()
        }
        
        self.pushNotificationSwitch.userInteractionEnabled = false
        if defaults.valueForKey(SubscriptionIDs.NewOfferSubscriptionID) != nil ||
            defaults.valueForKey(SubscriptionIDs.AcceptedOfferSubscriptionID) != nil {
            Model.sharedInstance().deleteSubscriptionsWithIDs([defaults.valueForKey(SubscriptionIDs.NewOfferSubscriptionID) as! String, defaults.valueForKey(SubscriptionIDs.AcceptedOfferSubscriptionID) as! String])
            
            Model.sharedInstance().subscribeForNewOffer(false, completionHandler: {
                Model.sharedInstance().subscribeForAcceptedOffer(false,completionHandler: {
                    self.pushNotificationSwitch.userInteractionEnabled = true
                })
            })
        } else {
            self.pushNotificationSwitch.on = !self.pushNotificationSwitch.on
            self.pushNotificationSwitch.userInteractionEnabled = true
        }
        logw("Pushnotification switch is now: \(pushNotificationSwitch.on)")
    }
    @IBAction func postToFacebookSwitchTapped(sender: UISwitch) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if sender.on == false{
            NSUserDefaults.standardUserDefaults().setValue("no", forKey: UniversalConstants.kIsPostingToFacebookOn)
        } else {
            NSUserDefaults.standardUserDefaults().setValue("yes", forKey: UniversalConstants.kIsPostingToFacebookOn)
        }
        logw("FacebookPost switch is now: \(sender.on)")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    @IBAction func termsAndConditionsButtonTapped(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let termsAndConditionNavigationController = storyboard!.instantiateViewControllerWithIdentifier("toTermsConditionNavigationController") as! UINavigationController
        if let termsAndConditionViewController = termsAndConditionNavigationController.childViewControllers[0] as? TermsConditionViewController {
            termsAndConditionViewController.fileToShow = TermsConditionViewController.FileOnDemand.terms
        }
        presentViewController(termsAndConditionNavigationController, animated: true, completion: nil)
    }
    @IBAction func safetyButtonTapped(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let termsAndConditionNavigationController = storyboard!.instantiateViewControllerWithIdentifier("toTermsConditionNavigationController") as! UINavigationController
        if let termsAndConditionViewController = termsAndConditionNavigationController.childViewControllers[0] as? TermsConditionViewController {
            termsAndConditionViewController.fileToShow = TermsConditionViewController.FileOnDemand.safety
        }
        presentViewController(termsAndConditionNavigationController, animated: true, completion: nil)
    }
    @IBAction func privacyPolicyButtonTapped(sender: UIButton) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let termsAndConditionNavigationController = storyboard!.instantiateViewControllerWithIdentifier("toTermsConditionNavigationController") as! UINavigationController
        if let termsAndConditionViewController = termsAndConditionNavigationController.childViewControllers[0] as? TermsConditionViewController {
            termsAndConditionViewController.fileToShow = TermsConditionViewController.FileOnDemand.privacyPolicy
        }
        presentViewController(termsAndConditionNavigationController, animated: true, completion: nil)
    }
    
  //MARK: - Handling Sliders
  
  private var distanceValues: [Float] = [1, 5, 10, 15, 20, 25]
  private var friendsValues: [Float] = [0, 1, 2]
  
  @IBOutlet weak var rangeLabel: UILabel!
  @IBOutlet weak var distanceSlider: UISlider!
  @IBOutlet weak var friendsSlider: UISlider!
  
  @IBAction func friendsSliderMoved(sender: UISlider) {
    switch sender.value {
    case 0..<0.5:
      sender.setValue(0, animated: true)
      break
    case 0.5..<1.5:
      sender.setValue(1, animated: true)
      break
    case 1.5...2:
      sender.setValue(2, animated: true)
      break
    default:
      assertionFailure("the slider's value is outside of the given range")
    }
    logw("Friends slider is set to: \(sender.value)")
    //check to make sure everything is within bounds of privacy settings
    if !FBSDKAccessToken.currentAccessToken().hasGranted("user_friends") {
      let manager = FBSDKLoginManager()
      manager.logInWithReadPermissions(["user_friends"], handler: { (loginResult, error) -> Void in
        if !loginResult.grantedPermissions.contains("user_friends") {
          self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
        }
      })
    }
  }
  
  @IBAction func distanceSliderFinishedMove(sender: UISlider) {
    switch sender.value {
    case 0..<2.5:
      sender.setValue(1, animated: true)
      break
    case 2.5..<7.5:
      sender.setValue(5, animated: true)
      break
    case 7.5..<12.5:
      sender.setValue(10, animated: true)
      break
    case 12.5..<17.5:
      sender.setValue(15, animated: true)
      break
    case 17.5..<22.5:
      sender.setValue(20, animated: true)
      break
    case 22.5..<MAXFLOAT:
      sender.setValue(25, animated: true)
      break
    default:
      assertionFailure("the slider's value is outside of the given range")
    }
    if sender.value == 25.0 {
      rangeLabel.text = "Everywhere"
    } else {
      rangeLabel.text = "\(Int(sender.value)) mi"
    }
    logw("Distance Slider is set to: \(sender.value)")
    //check to make sure everything is within bounds of privacy settings
    if sender.value == sender.maximumValue { return }
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
      locationManager.requestAlwaysAuthorization()
    } else if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showMustChangeLocationSettingAlert()
    }
  }
  
  @IBAction func distanceSliderMoved(sender: UISlider) {
    var closestDistanceValue = Float()
    
    for value in distanceValues {
      if abs(sender.value - value) < abs(sender.value - closestDistanceValue) {
        closestDistanceValue = value
      }
    }
    if closestDistanceValue == 25.0 {
      rangeLabel.text = "Everywhere"
    } else {
      rangeLabel.text = "\(Int(closestDistanceValue)) mi"
    }
  }
  
  //MARK: - UITableView Delegate Methods
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch indexPath {
    case Constants.AboutIndexPath:
      UIApplication.sharedApplication().openURL(Constants.AboutURL!)
      break
    case Constants.DeveloperIndexPath:
      UIApplication.sharedApplication().openURL(Constants.DeveloperWebsiteURL!)
      break
    default:
      break
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  //MARK: - Alerts
    private func showMustChangeLocationSettingAlert() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let title = "Can't Access Location"
    let message = "We don't know where you are! You can change the location settings in the Settings app or keep your range as Everywhere."
    let cancelTitle = "Dismiss"
    let settingsTitle = "Settings"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
      
    }
    let settingsAction = UIAlertAction(title: settingsTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
      UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
      self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
    }
    alert.addAction(cancelAction)
    alert.addAction(settingsAction)
    presentViewController(alert, animated: true, completion: nil)
  }
    private func mustChangeFacebookFriendsAccessSetting() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let title = "Can't Access Friends"
    let message = "Because of your security settings, we can't see who your friends are on Facebook! You can change that in Settings later, but for now, you'll see everyone's posts."
    let cancelTitle = "Dismiss"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
    }
    
    alert.addAction(cancelAction)
    presentViewController(alert, animated: true, completion: nil)
  }
    
    
    func sendReportWithAttachment() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if( MFMailComposeViewController.canSendMail() ) {
            logw("Can send email.")
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            let me = Person.MR_findFirstByAttribute("me", withValue: true)
            //Set the subject and message of the email
            mailComposer.setSubject("Peruze log.")
            mailComposer.setMessageBody("Hello, I am \(me.valueForKey("firstName")!) \(me.valueForKey("lastName")!).", isHTML: false)
            mailComposer.setToRecipients(["vijay@systematixtechnocrates.com"])
            
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            do {
                let directoryUrls = try  NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
                logw("\(directoryUrls)")
                let logFilePaths = directoryUrls.filter(){ $0.pathExtension == "log" }
//                let logFiles = directoryUrls.filter(){ $0.pathExtension == "log" }.map{ $0.lastPathComponent }
                let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                let pathString = "\(path)"
                let files = NSFileManager.defaultManager().enumeratorAtPath("\(pathString)")
                while let file = files?.nextObject() {
                    logw("\(file)")
//                }
//                for logFile in logFiles {
                    if file.hasSuffix(".log") == true {
                        if let fileData = NSData(contentsOfFile: "\(pathString)/\(file.description!)") {
                            logw("File data loaded.")
                            mailComposer.addAttachmentData(fileData, mimeType: "text/rtf", fileName: "Logs")
                        }
                        logw("Log FILES:\n" + logFilePaths.description)
                    }
                }
            } catch let error as NSError {
                logw(error.localizedDescription)
            }
            //                var getImagePath1 = paths1.stringByAppendingPathComponent("\(logFiles[0])")
            //                for paths in logFilePaths {
            //                    if let fileData = NSData(contentsOfFile: "\(paths)".stringByReplacingOccurrencesOfString("file://", withString: "").stringByReplacingOccurrencesOfString("var://", withString: "")) {
            //                        logw("File data loaded.")
            //                        mailComposer.addAttachmentData(fileData, mimeType: "text/rtf", fileName: "Logs")
            //                    }
            //                    logw("Log FILES:\n" + paths.description)
            //                }
            
//            if let filePath = NSBundle.mainBundle().pathForResource("swifts", ofType: "wav") {
//                logw("File path loaded.")
//                
//                if let fileData = NSData(contentsOfFile: filePath) {
//                    logw("File data loaded.")
//                    mailComposer.addAttachmentData(fileData, mimeType: "audio/wav", fileName: "swifts")
//                }
//            }
            self.presentViewController(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.dismissViewControllerAnimated(true, completion: nil)
        if error != nil{
            let alertController = UIAlertController(title: "Peruzr", message: "There was an error while sending mail. Please try again later.", preferredStyle: .Alert)
            
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
  
}
