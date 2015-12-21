
//
//  AppDelegate.swift
//  Peruse
//
//  Created by Phillip Trent on 5/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  private struct Constants {
    static let AppDidBecomeActiveNotificationName = "applicationDidBecomeActive"
  }
    func resetBadgeCounter() {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: 0)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                logw("Error resetting badge: \(error)")
                self.resetBadgeCounter()
            }
            else {
                //                self.setRequestBadgeCount(0)
            }
        }
        CKContainer.defaultContainer().addOperation(badgeResetOperation)
    }
    
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    // Setup CoreData with MagicalRecord
    if NSUserDefaults.standardUserDefaults().valueForKey("appLaunchedOnce") == nil{
       NSUserDefaults.standardUserDefaults().setValue("yes", forKey: "appLaunchedOnce")
       UIApplication.sharedApplication().applicationIconBadgeNumber = 0
       resetBadgeCounter()
    }
    if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) == nil {
        NSUserDefaults.standardUserDefaults().setValue(UniversalConstants.kIsPushNotificationOn, forKey: "yes")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPostingToFacebookOn) == nil {
        NSUserDefaults.standardUserDefaults().setValue(UniversalConstants.kIsPostingToFacebookOn, forKey: "yes")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    MagicalRecord.setupCoreDataStackWithStoreNamed("PeruzeDataModel")
    //MagicalRecord.setLoggingLevel(MagicalRecordLoggingLevel.Verbose)
    
    if (launchOptions != nil) {
    if let notification:NSDictionary = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
        //do stuff with notification
//        NSLog([NSString stringWithFormat:@"Launched from push notification: %@", dictionary]);
//        [[RemoteNotificationManager sharedInstance] sendLocalNotificationAfterRemoteNotification:dictionary andShowAlerts:YES];
        logw("notification \(notification)")
    }
    }
    
    //Branch.io
    let branch: Branch = Branch.getInstance()
    branch.setDebug()
    branch.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
        if (error == nil) {
            NSLog("params: %@", params.description)
        }
    })
    
    return FBSDKApplicationDelegate.sharedInstance().application(application,
      didFinishLaunchingWithOptions: launchOptions)
  }
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    Branch.getInstance().handleDeepLink(url);
    return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
  }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        
        return Branch.getInstance().continueUserActivity(userActivity)
    }
  
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
    NSFetchedResultsController.deleteCacheWithName("PeruzeDataModel")
  }
    
  //MARK: - Push Notifications
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    logw(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>app did receive remote notification ")
    
    let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
    if let notification = cloudKitNotification as? CKQueryNotification {
      logw("app did receive remote notification ")
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
        logw("\(userInfo)")
        if var info = userInfo["aps"] as? Dictionary<String, AnyObject> {
            logw("All of info: \n\(info)\n")
            
            if let _ = info["alert"] as? String {
                info["recordID"] = notification.recordID?.recordName
                NSNotificationCenter.defaultCenter().postNotificationName("ShowBadgeOnRequestTab", object:nil , userInfo: info)
            }
            if  let badge = info["badge"] as? Int {
                logw("\nFrom APS-dictionary with key \"type\":  \( badge)")     
            }
        }
    }
  }
    
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    logw("app did register for remote notification ")
  }
    
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    logw(error.localizedDescription)
  }
    
}

