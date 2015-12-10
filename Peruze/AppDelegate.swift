
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
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    // Setup CoreData with MagicalRecord
    
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
    

    
    return FBSDKApplicationDelegate.sharedInstance().application(application,
      didFinishLaunchingWithOptions: launchOptions)
  }
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
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
    
//    let dict = userInfo[0]
//    let aps = userInfo.valueForKey("aps")
//    let badgeValue = aps!.valueForKey("badge")
//    logw(badgeValue)
    
    let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
    if let notification = cloudKitNotification as? CKQueryNotification {
      logw("app did receive remote notification ")
      NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
        
        if let info = userInfo["aps"] as? Dictionary<String, AnyObject> {
            // Default printout of info = userInfo["aps"]
            logw("All of info: \n\(info)\n")
            
            for (key, value) in info {
                logw("APS: \(key) —> \(value)")
            }
            
            if  let alert = info["alert"] as? String {
                // Printout of (userInfo["aps"])["type"]
                logw("\nFrom APS-dictionary with key \"type\":  \( alert)")
                NSNotificationCenter.defaultCenter().postNotificationName("ShowBadgeOnRequestTab", object:info)
            }
            if  let badge = info["badge"] as? Int {
                logw("\nFrom APS-dictionary with key \"type\":  \( badge)")
            }
        }
//        let viewController: ViewController =
//        self.window?.rootViewController as! ViewController
        
        
        
        if (cloudKitNotification.notificationType ==
            CKNotificationType.Query) {
                
                let queryNotification = notification 
                
                let recordID = queryNotification.recordID
                
                logw("Query Added exchange recordId = \(recordID)")
//                viewController.fetchRecord(recordID)
        } else if (cloudKitNotification.notificationType ==
            CKNotificationType.RecordZone) {
                
                let queryNotification = notification
                
                let recordID = queryNotification.recordID
                
                logw("RecordZone Added exchange recordId = \(recordID)")
                //                viewController.fetchRecord(recordID)
        } else if (cloudKitNotification.notificationType ==
            CKNotificationType.ReadNotification) {
                
                let queryNotification = notification
                
                let recordID = queryNotification.recordID
                
                logw("ReadNotification Added exchange recordId = \(recordID)")
                //                viewController.fetchRecord(recordID)
        }
        
    }
  }
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    logw("app did register for remote notification ")
  }
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    logw(error.localizedDescription)
  }
    
    
//    func fetchRecord(recordID: CKRecordID) -> Void
//    {
//        publicDatabase = container.publicCloudDatabase
//        
//        publicDatabase?.fetchRecordWithID(recordID,
//            completionHandler: ({record, error in
//                if let err = error {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        self.notifyUser("Fetch Error", message:
//                            err.localizedDescription)
//                    }
//                } else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        self.currentRecord = record
//                        self.addressField.text =
//                            record.objectForKey("address") as! String
//                        self.commentsField.text =
//                            record.objectForKey("comment") as! String
//                        let photo =
//                        record.objectForKey("photo") as! CKAsset
//                        
//                        let image = UIImage(contentsOfFile:
//                            photo.fileURL.path!)
//                        self.imageView.image = image
//                        self.photoURL = self.saveImageToFile(image!)
//                    }
//                }
//            }))
//    }

    
}

