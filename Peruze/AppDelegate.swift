
//
//  AppDelegate.swift
//  Peruse
//
//  Created by Phillip Trent on 5/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit
import CloudKit
import MagicalRecord

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  private struct Constants {
    static let AppDidBecomeActiveNotificationName = "applicationDidBecomeActive"
  }
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    // Setup CoreData with MagicalRecord
    
    MagicalRecord.setupCoreDataStackWithStoreNamed("PeruzeDataModel")
    MagicalRecord.setLoggingLevel(MagicalRecordLoggingLevel.Verbose)
    return FBSDKApplicationDelegate.sharedInstance().application(application,
      didFinishLaunchingWithOptions: launchOptions)
  }
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
    return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
  }
  
  //Swift 2.0
//  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
//    return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
//  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    FBSDKAppEvents.activateApp()
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: Constants.AppDidBecomeActiveNotificationName, object: true))
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    MagicalRecord.cleanUp()
  }
  //MARK: - Push Notifications
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    print("app did receive remote notification")
    let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
    if let _ = cloudKitNotification as? CKQueryNotification {
      print("app did receive remote notification")
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
    }
  }
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    print("app did register for remote notification")
  }
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    print(error.localizedDescription)
  }
}

