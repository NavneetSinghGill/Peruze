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
    static let friendsViewControllerSegueIdentifier = "toFriendsViewControllerSegueIdentifier"
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
  
  //MARK: Local Vars
  private var facebookData = FacebookDataSource()
  private var locationManager = CLLocationManager()
  var percentLoaded: Int?
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
  
  //MARK: - View Controller Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    facebookData.profilePictureRetrievalDelegate = self
    facebookData.getProfilePhotosWithCompletion { [unowned self] (success, error) -> Void in
      if !success {
        logw("\(error)")
        self.profilePictureFetchingError()
      }
      self.loadingCircle?.stop()
    }
    //distance
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
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewWillAppear(animated)
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
    let loadingX: CGFloat = 0
    let loadingY: CGFloat = 0
    let loadingSideLength = min(loadingViewContainer.frame.width, loadingViewContainer.frame.height)
    loadingCircle = LoadingCircleView(frame: CGRectMake(loadingX, loadingY, loadingSideLength, loadingSideLength))
    loadingCircle!.backgroundColor = .clearColor()
    loadingCircle!.fullRotationCompletionDuration = Constants.LoadSpeed
    loadingCircle!.fadeOutAnimationDuration = Constants.LoadFadeDuration
    loadingViewContainer.addSubview(loadingCircle!)
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
    self.tap(upperLeft)
  }
  
  //MARK: - Errors and Alerts
  private func profilePictureFetchingError() {
    let notEnoughProfilePicturesAlertView = UIAlertView(title: Constants.Alerts.ProfilePhoto.Title,
      message: Constants.Alerts.ProfilePhoto.Message,
      delegate: nil,
      cancelButtonTitle: Constants.Alerts.ProfilePhoto.CancelButton)
    notEnoughProfilePicturesAlertView.show()
    for view in [upperLeft, upperRight, lowerLeft, lowerRight] { view.hidden = true }
  }
  
  private func logOutOfFacebookAlertWithCompletion(completion: (Bool -> Void)) {
    //TODO: you're about to log out of facebook
    completion(true)
  }
  
  private func deleteAccountAlertWithCompletion(completion: (Bool -> Void)) {
    //TODO: you're about to permanently delete everything
    completion(true)
  }
  
  //MARK: - Gesture Handling
  @IBAction func tapUpperLeft(sender: UITapGestureRecognizer) {
    tap(upperLeft)
  }
  @IBAction func tapLowerLeft(sender: UITapGestureRecognizer) {
    tap(lowerLeft)
  }
  @IBAction func tapUpperRight(sender: UITapGestureRecognizer) {
    tap(upperRight)
  }
  @IBAction func tapLowerRight(sender: UITapGestureRecognizer) {
    tap(lowerRight)
  }
  private func tap(selectedImage: CircleImage) {
    for obj in [upperLeft, upperRight, lowerRight, lowerLeft] { obj.selected = false }
    selectedImage.selected = true
    profilePicUpdate(selectedImage)
  }
    func profilePicUpdate(selectedImage: CircleImage){
            selectedCircleImage = selectedImage
    }
  //MARK: - Handling Buttons
  @IBAction func logOutOfFacebook(sender: UIButton) {
    FBSDKAccessToken.setCurrentAccessToken(nil)
    FBSDKLoginManager().logOut()
    dismissViewControllerAnimated(false, completion: nil)
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "showIniticiaViewController", object: nil, userInfo: nil))
  }
  
  @IBAction func deleteProfile(sender: UIButton) {
    return
//    FBSDKAccessToken.setCurrentAccessToken(nil)
    NSUserDefaults.standardUserDefaults().setObject(false, forKey: UserDefaultsKeys.ProfileHasActiveProfileKey)
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func done(sender: UIBarButtonItem) {
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
            let dict:[String:AnyObject] = ["circleImage":selectedCircleImage]
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "profileUpdate", object: nil, userInfo: dict))
      dismissViewControllerAnimated(true) {
        //Model.sharedInstance().fetchItemsWithinRangeAndPrivacy()
        //TODO: Pass edited data back to dataSource
      }
    }
  }
  
    @IBAction func inviteFacebookFriendsButtonTapped(sender: UIButton) {
//        performSegueWithIdentifier(Constants.friendsViewControllerSegueIdentifier, sender: self)
    }
    
    @IBAction func sendLogs(sender: UIButton) {
        sendReportWithAttachment()
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
        logw("\(__FUNCTION__)")
        if( MFMailComposeViewController.canSendMail() ) {
            logw("Can send email.")
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            let me = Person.MR_findFirstByAttribute("me", withValue: true)
            //Set the subject and message of the email
            mailComposer.setSubject("Peruze log.")
            mailComposer.setMessageBody("Hello, I am \(me.valueForKey("firstName")!) \(me.valueForKey("lastName")!).", isHTML: false)
            mailComposer.setToRecipients(["navneet105gill@gmail.com"])
            
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
        self.dismissViewControllerAnimated(true, completion: nil)
        if error != nil{
            let alertController = UIAlertController(title: "Peruzr", message: "There was an error while sending mail. Please try again later.", preferredStyle: .Alert)
            
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
  
}
