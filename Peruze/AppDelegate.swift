
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
  
    func resetBadgeCounter() {
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        
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
    logw("\n\n\n##################################  APPLICATION STARTING POINT  ##################################\n\n\n")
    // Override point for customization after application launch.
    // Setup CoreData with MagicalRecord
    let defaults = NSUserDefaults.standardUserDefaults()
    if defaults.valueForKey("appLaunchedOnce") == nil{
       defaults.setValue("yes", forKey: "appLaunchedOnce")
        defaults.synchronize()
       UIApplication.sharedApplication().applicationIconBadgeNumber = 0
       resetBadgeCounter()
        Model.sharedInstance().deleteAllSubscription()
    }
    if defaults.valueForKey(UniversalConstants.kIsPushNotificationOn) == nil {
        defaults.setValue("yes", forKey: UniversalConstants.kIsPushNotificationOn)
        defaults.synchronize()
    }
    if defaults.valueForKey(UniversalConstants.kIsPostingToFacebookOn) == nil {
        defaults.setValue("yes", forKey: UniversalConstants.kIsPostingToFacebookOn)
        defaults.synchronize()
    }
    defaults.setBool(true, forKey: "isAppActive")
    MagicalRecord.setupCoreDataStackWithStoreNamed("PeruzeDataModel")
    //MagicalRecord.setLoggingLevel(MagicalRecordLoggingLevel.Verbose)
    
    if (launchOptions != nil) {
    if let notification:NSDictionary = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
        //do stuff with notification
//        NSLog([NSString stringWithFormat:@"Launched from push notification: %@", dictionary]);
//        [[RemoteNotificationManager sharedInstance] sendLocalNotificationAfterRemoteNotification:dictionary andShowAlerts:YES];
        logw("DidfinishlaunWithOptions notification: \(notification)")
        self.postLocalNotifications(notification)
    }
    }
    
    //Branch.io
    let branch: Branch = Branch.getInstance()
    branch.setDebug()
    branch.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
        if (error == nil) {
            logw("params:\(params.description)")
            if let recordID = params["recordID"] as? String {
                NSNotificationCenter.defaultCenter().postNotificationName("ScrollTOShowSharedItem", object: nil, userInfo: ["recordID":recordID])
            }
        }
    })
    
    //Exception handler
    NSSetUncaughtExceptionHandler { exception in
        logw("NSSetUncaughtExceptionHandler exception : \(exception)")
        logw("NSSetUncaughtExceptionHandler callStackSymbols: \(exception.callStackSymbols)")
    }
    
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
    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isAppActive")
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isAppActive")
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    FBSDKAppEvents.activateApp()
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isAppActive")
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "applicationDidBecomeActive", object: true))
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    MagicalRecord.cleanUp()
    NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isAppActive")
    NSFetchedResultsController.deleteCacheWithName("PeruzeDataModel")
    logw("\n\n##########################  APPLICATION WILL TERMINATE  ##########################\n\n")
  }
    
  //MARK: - Push Notifications
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    logw(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>app did receive remote notification ")
    
    self.postLocalNotifications(userInfo)
  }
    
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    logw("app did register for remote notification ")
  }
    
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    logw(error.localizedDescription)
  }
    
    //Private methods:
    
    func postLocalNotifications(userInfo: NSDictionary) {
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
        if let notification = cloudKitNotification as? CKQueryNotification {
            logw("app did receive remote notification ")
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
            logw("Notification: \(notification) \n UserInfo: \(userInfo)")
            if var info = userInfo["aps"] as? Dictionary<String, AnyObject> {
                logw("All of info: \n\(info)\n")
                
                if let _ = info["category"] as? String {
                    info["recordID"] = notification.recordID?.recordName
                    NSNotificationCenter.defaultCenter().postNotificationName("ShowBadgeOnRequestTab", object:nil , userInfo: info)
                }
                if  let badge = info["badge"] as? Int {
                    logw("\nFrom APS-dictionary with key \"type\":  \( badge)")
                }
            }
        }
    }
    
}

