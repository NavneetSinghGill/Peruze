//
//  ProfileSetupRangeViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 5/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
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
    
    distanceValues.sortInPlace(<)
    distanceSlider.minimumValue = distanceValues.first!
    distanceSlider.maximumValue = distanceValues.last!
    distanceSlider.setValue(distanceSlider.maximumValue, animated: false)
    //friends
    
    friendsValues.sortInPlace(<)
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
      options: [.Repeat, .CurveEaseInOut], animations: {
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
      let alert = ErrorAlertFactory.locationEverywhereOnlyAccessAlert {
        self.userWarnedAboutLimitedFunction = true
        self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
        self.updateCircleView(self.distanceSlider.value)
      }
      presentViewController(alert, animated: true, completion: nil)
    }
  }
  
  @IBAction func info(sender: UIButton) { /*segues to info view*/ }
  
  
  //makes sure the user is warned that denying location permissions results in limited functionality
  var userWarnedAboutLimitedFunction = false
  
  @IBAction func done(sender: UIButton) {
    //check location authorizations
    if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
      print("authorization status not determined")
      locationManager.requestAlwaysAuthorization()
      return
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways && !userWarnedAboutLimitedFunction {
      print("User hasn't been warned")
      let alert = ErrorAlertFactory.locationEverywhereOnlyAccessAlert {
        self.userWarnedAboutLimitedFunction = true
        self.distanceSlider.setValue(self.distanceSlider.maximumValue, animated: true)
        self.updateCircleView(self.distanceSlider.value)
      }
      
      presentViewController(alert, animated: true, completion: nil)
      return
    }
    
    //check facebook access
    if !FBSDKAccessToken.currentAccessToken().hasGranted("user_friends") && !FBSDKAccessToken.currentAccessToken().declinedPermissions.contains("user_friends") {
      print("checking facebook access for granted permission")
      let manager = FBSDKLoginManager()
      manager.logInWithReadPermissions(["user_friends"], handler: { (loginResult, error) -> Void in
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          print("login result retrieved with error \(error)")
          if error != nil {
            let alert = ErrorAlertFactory.alertFromError(error, dismissCompletion: nil)
            self.presentViewController(alert, animated: true, completion: nil)
            return
          }
          if !loginResult.grantedPermissions.contains("user_friends") {
            let alert = ErrorAlertFactory.friendSettingNoAccessAlert()
            self.presentViewController(alert, animated: true, completion: nil)
            self.friendsSlider.setValue(self.friendsSlider.maximumValue, animated: true)
            return
          }
        })
      })
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
  
  
}
