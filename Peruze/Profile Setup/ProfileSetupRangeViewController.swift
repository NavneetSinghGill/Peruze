//
//  ProfileSetupRangeViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 5/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import CoreLocation

struct UserDefaultsKeys {
  static let ProfileHasActiveProfileKey = "UserHasActiveProfile"
  static let UsersDistancePreference = "UserRadiusFromLocation"
  static let UsersFriendsPreference = "UserFriendVisibility"
}
enum FriendsPrivacy: Int {
  case Friends = 0, FriendsOfFriends, Everyone
}
class ProfileSetupRangeViewController: UIViewController, CLLocationManagerDelegate {
  private struct Constants {
    static let PulseCircleAnimationDuration = 1.25
  }
  //MARK: - Variables
  private var distanceValues: [Float] = [1, 5, 10, 15, 20, 25]
  private var friendsValues: [Float] = [0, 1, 2]
  private var locationManager = CLLocationManager()
  
  @IBOutlet weak var profileImageView: CircleImage!
  @IBOutlet weak var rangeLabel: UILabel!
  @IBOutlet weak var distanceSlider: UISlider!
  @IBOutlet weak var friendsSlider: UISlider!
  
  private var circleView: CircleView?
  private var pulseCircleView: CircleView?
  var profileImage: UIImage?
  
  //MARK: - View Controller Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    //distance
    distanceValues.sort(<)
    distanceSlider.minimumValue = distanceValues.first!
    distanceSlider.maximumValue = distanceValues.last!
    distanceSlider.setValue(distanceSlider.maximumValue, animated: false)
    //friends
    friendsValues.sort(<)
    friendsSlider.minimumValue = friendsValues.first!
    friendsSlider.maximumValue = friendsValues.last!
    friendsSlider.setValue(friendsSlider.maximumValue, animated: false)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    updateCircleView(distanceSlider.value)
    profileImageView.image = profileImage
    navigationController
    view.clipsToBounds = true
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    circleView?.removeFromSuperview()
    circleView = nil
    pulseCircleView?.removeFromSuperview()
    pulseCircleView = nil
  }
  
  //MARK: - Custom Drawing
  private func updateCircleView(displayValue: Float) {
    if displayValue != distanceValues.last! {
      rangeLabel!.text = "\(Int(displayValue)) mi"
    } else {
      rangeLabel!.text = "Everywhere"
    }
    drawCircle(distanceSlider.value, animated: true)
  }
  private func drawCircle(multiplier: Float, animated: Bool) {
    //calculate the circle radius
    let maxV = view.bounds.width >= view.bounds.height ? view.bounds.height / 2 : view.bounds.width / 2
    let minV = rangeLabel.bounds.width
    
    let maxMult = distanceValues[distanceValues.count - 1]
    let minMult = distanceValues.first!
    let unitMult = (multiplier - minMult) / (maxMult - minMult)
    
    let calculatedRadius = unitMult * Float(maxV - minV) + Float(minV)
    var drawingRadius = CGFloat()
    if unitMult >= 1 {
      drawingRadius = CGFloat(calculatedRadius * 1.5)
    } else {
      drawingRadius = CGFloat(calculatedRadius)
    }
    
    //calculate the circle's frame
    let circleX = (view.bounds.width / 2) - drawingRadius
    let circleY = (view.bounds.height / 2) - drawingRadius
    let circleRect = CGRectMake(circleX, circleY, drawingRadius * 2, drawingRadius * 2)
    
    //draw the circle view
    if circleView == nil {
      circleView = CircleView(frame: circleRect)
      circleView!.backgroundColor = UIColor.clearColor()
      view.insertSubview(circleView!, atIndex: 0)
    } else {
      if(animated) {
        UIView.transitionWithView(circleView!, duration: 0.5, options: .CurveEaseIn, animations: { () -> Void in
          self.circleView!.frame = circleRect
          }, completion: { (success) -> Void in })
      } else {
        self.circleView!.frame = circleRect
      }
      circleView!.setNeedsDisplay()
    }
    pulseCircle(circleView!.frame)
  }
  
  private func pulseCircle(destinationRect:CGRect) {
    if pulseCircleView == nil {
      pulseCircleView = CircleView()
      pulseCircleView!.backgroundColor = UIColor.clearColor()
      view.insertSubview(pulseCircleView!, atIndex: 0)
    }
    pulseCircleView!.frame = CGRectMake(view.bounds.width / 2, view.bounds.height / 2, 0, 0)
    pulseCircleView!.layer.removeAllAnimations()
    UIView.transitionWithView(pulseCircleView!, duration: Constants.PulseCircleAnimationDuration,
      options: .Repeat | .CurveEaseInOut, animations: {
        self.pulseCircleView!.frame = destinationRect
        self.pulseCircleView!.setNeedsDisplay()
      }, completion: nil)
  }
  
  //MARK: - Actions
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
  
  @IBAction func distanceSliderMoved(sender: UISlider) {
    var closestDistanceValue = Float()
    
    for value in distanceValues {
      if abs(sender.value - value) < abs(sender.value - closestDistanceValue) {
        closestDistanceValue = value
      }
    }
    updateCircleView(closestDistanceValue)
  }
  
  @IBAction func distanceSliderFinishedMove(sender: UISlider) {
    var closestDistanceValue = Float()
    for value in distanceValues {
      if abs(sender.value - value) < abs(sender.value - closestDistanceValue) {
        closestDistanceValue = value
      }
    }
    sender.setValue(closestDistanceValue, animated: true)
    updateCircleView(closestDistanceValue)
    
    //check to make sure everything is within bounds of privacy settings
    if sender.value == sender.maximumValue { return }
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
      locationManager.requestAlwaysAuthorization()
    } else if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showMustChangeLocationSettingAlert()
    }
  }
  
  @IBAction func info(sender: UIButton) { /*segues to info view*/ }
  
  
  //makes sure the user is warned that denying location permissions results in limited functionality
  var userWarnedAboutLimitedFunction = false
  
  @IBAction func done(sender: UIButton) {
    //check location authorizations
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
      locationManager.requestAlwaysAuthorization()
      return
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways && !userWarnedAboutLimitedFunction {
      showOptionalChangeLocationSettingAlert()
      return
    }
    
    //check facebook access
    if !FBSDKAccessToken.currentAccessToken().hasGranted("user_friends") && !FBSDKAccessToken.currentAccessToken().declinedPermissions.contains("user_friends") {
      let manager = FBSDKLoginManager()
      manager.logInWithReadPermissions(["user_friends"], handler: { (loginResult, error) -> Void in
        if !loginResult.grantedPermissions.contains("user_friends") {
          self.optionalChangeFacebookFriendsAccessSetting()
          self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
        }
      })
      return
    }
    
    //check slider and authorization alignment
    if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways && distanceSlider.value != distanceSlider.maximumValue {
      assertionFailure("authorization status and distance slider do not correspond")
    }
    if !FBSDKAccessToken.currentAccessToken().hasGranted("user_friends") && friendsSlider.value != friendsSlider.maximumValue {
      assertionFailure("authorization status and friends slider do not correspond")
    }
    
    //set all values and dismiss
    NSUserDefaults.standardUserDefaults().setObject(Int(distanceSlider.value), forKey: UserDefaultsKeys.UsersDistancePreference)
    NSUserDefaults.standardUserDefaults().setObject(Int(friendsSlider.value), forKey: UserDefaultsKeys.UsersFriendsPreference)
    NSUserDefaults.standardUserDefaults().setObject(true, forKey: UserDefaultsKeys.ProfileHasActiveProfileKey)
    dismissViewControllerAnimated(true, completion: nil)
    
  }
  
  //MARK: - Alerts
  private func showMustChangeLocationSettingAlert() {
    let message = "We don't know where you are! If you don't allow location services, then only others who have their range set to Everywhere will be able to see you."
    let alert = changeLocationAlert(message)
    presentViewController(alert, animated: true, completion: nil)
  }
  private func showOptionalChangeLocationSettingAlert() {
    let message = "If you leave don't allow location services, your location will be anonymous, and only others who also have their range set to 'Everyone' will be able to see your profile."
    let alert = changeLocationAlert(message)
    presentViewController(alert, animated: true, completion: nil)
    userWarnedAboutLimitedFunction = true
  }
  private func changeLocationAlert(message: String) -> UIAlertController {
    let title = "Can't Access Location"
    let cancelTitle = "Dismiss"
    let settingsTitle = "Settings"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
      self.updateCircleView(self.distanceSlider.value)
      
    }
    let settingsAction = UIAlertAction(title: settingsTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
      UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
      self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
      self.updateCircleView(self.distanceSlider.value)
    }
    alert.addAction(cancelAction)
    alert.addAction(settingsAction)
    return alert
  }
  private func mustChangeFacebookFriendsAccessSetting() {
    let message = "Because of your security settings, we can't see who your friends are on Facebook! You can change that in Settings later, but for now, you'll see everyone's posts."
    let alert = facebookFriendsAlert(message)
    presentViewController(alert, animated: true, completion: nil)
  }
  private func optionalChangeFacebookFriendsAccessSetting() {
    let message = "If you will allow us to access your friends, we can show mutual friends between you and other Peruzers. "
    let alert = facebookFriendsAlert(message)
    presentViewController(alert, animated: true, completion: nil)
  }
  private func facebookFriendsAlert(message: String) -> UIAlertController {
    let title = "Can't Access Friends"
    let cancelTitle = "Dismiss"
    let settingsTitle = "Allow Access"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
    }
    let settingsAction = UIAlertAction(title: settingsTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
      self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
      let manager = FBSDKLoginManager()
      manager.logInWithReadPermissions(["user_friends"], handler: { (loginResult, error) -> Void in
        if !loginResult.grantedPermissions.contains("user_friends") {
          self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
        }
      })
    }
    alert.addAction(cancelAction)
    return alert
  }
}
