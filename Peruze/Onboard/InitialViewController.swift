//
//  InitialViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/14/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SystemConfiguration
import FBSDKLoginKit
import CloudKit
import MagicalRecord

class InitialViewController: UIViewController {
  
  private struct Constants {
    static let OnboardVCIdentifier = "OnboardViewController"
    static let TabBarVCIdentifier = "MainTabBarViewController"
    static let ProfileVCIdentifier = "ProfileSetupNavigationController"
  }
  var spinner: UIActivityIndicatorView!
  var facebookLoginWasSuccessful = false
  var onboardVC: UIViewController?
  var tabBarVC: UITabBarController?
  var profileSetupVC: UIViewController?
  
  //MARK: - View Controller Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    view.addSubview(spinner)
    spinner.hidesWhenStopped = true
    spinner.startAnimating()
    
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    spinner.frame = view.frame
  }
  override func viewDidAppear(animated: Bool) {
    spinner.startAnimating()
    if presentedViewController == nil && presentingViewController == nil {
      segueToCorrectVC()
    }
  }
  
  //MARK: - Segues
  func segueToCorrectVC() {
    if !NetworkConnection.connectedToNetwork() {
      let alert = ErrorAlertFactory.alertForNetworkWithTryAgainBlock() { [unowned self] Void in
        self.segueToCorrectVC()
      }
      presentViewController(alert, animated: true, completion: nil)
      return
    }
    if presentedViewController != nil || presentingViewController != nil || childViewControllers.count != 0 { return }
    if storyboard == nil { assertionFailure("Storyboard is not initialized ") }
    if FBSDKAccessToken.currentAccessToken() == nil {
      spinner.stopAnimating()
      setupAndSegueToOnboardVC()
    } else {
      let getMyProfileOp = GetCurrentUserOperation(database: CKContainer.defaultContainer().publicCloudDatabase)
      getMyProfileOp.completionBlock = {
        print("Finished")
        let myPerson = Person.MR_findFirstByAttribute("me", withValue: true) as Person!
        self.spinner.stopAnimating()
        
        if myPerson?.firstName == nil { self.setupAndSegueToSetupProfileVC(); return }
        if myPerson!.firstName!.isEmpty { self.setupAndSegueToSetupProfileVC(); return }
        if myPerson?.lastName == nil { self.setupAndSegueToSetupProfileVC(); return }
        if myPerson!.lastName!.isEmpty { self.setupAndSegueToSetupProfileVC(); return }
        //if there isn't anything wrong with my profile, segue to tab bar
        self.setupAndSegueToTabBarVC()
      }
      OperationQueue().addOperation(getMyProfileOp)
    }
  }
  
  @IBAction func unwindToInitialViewController(segue: UIStoryboardSegue) { /* do nothing for now */ }
  
  //MARK: - Not logged into facebook
  private func setupAndSegueToOnboardVC() {
    FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
    if presentedViewController == onboardVC && onboardVC != nil { print("pVC = onboard"); return }
    onboardVC = storyboard!.instantiateViewControllerWithIdentifier(Constants.OnboardVCIdentifier)
    if onboardVC == nil { assertionFailure("VC Pulled out of storyboard is not a UIViewController") }
    presentViewController(onboardVC!, animated: true, completion: nil)
  }
  
  //MARK: - Logged into facebook
  private func setupAndSegueToSetupProfileVC() {
    profileSetupVC = profileSetupVC ?? storyboard!.instantiateViewControllerWithIdentifier(Constants.ProfileVCIdentifier)
    if profileSetupVC == nil { assertionFailure("VC Pulled out of storyboard is not a ProfileSetupSelectPhotoViewController")}
    presentViewController(profileSetupVC!, animated: true, completion: nil)
  }
  
  //MARK: - Logged into facebook and profile setup
  private func setupAndSegueToTabBarVC() {
    tabBarVC = tabBarVC ?? storyboard!.instantiateViewControllerWithIdentifier(Constants.TabBarVCIdentifier) as? UITabBarController
    if tabBarVC == nil { assertionFailure("VC Pulled out of storyboard is not a UITabBarController")}
    tabBarVC!.selectedIndex = profileSetupVC == nil ? 0 : 1
    self.presentViewController(tabBarVC!, animated: true, completion: nil)
  }
  
  //MARK: - Alert
  private func alertForFetchProfileError() -> UIAlertController {
    let alert = UIAlertController(title: "Error Fetching Profile", message: "It looks like there was a problem fetching your profile from our server.", preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
    return alert
  }
  
}
