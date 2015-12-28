//
//  MainTabBarViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/7/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

class MainTabBarViewController: UITabBarController {
  override func viewDidLoad() {
    super.viewDidLoad()
    tabBar.tintColor = UIColor.redColor()
    self.registerNotifications()
  }
  //GO HERE
  let manager = CLLocationManager()
  override func viewDidAppear(animated: Bool) {
    manager.requestWhenInUseAuthorization()
  }
    
    //MARK: - Private methods

    func registerNotifications() {
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "showTabBar:",name:"showIniticiaViewController",object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "showBadgeOnRequestTab:",name:"ShowBadgeOnRequestTab",object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "resetBadgeValue",name:"ResetBadgeValue",object: nil)
    }
    func showTabBar(notification: NSNotification){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func showBadgeOnRequestTab(notification: NSNotification){
        if notification.userInfo != nil{
            let info : NSDictionary = notification.userInfo!
            if  let category = info["category"] as? String {
                // Printout of (userInfo["aps"])["type"]
                print("\nFrom APS-dictionary with key \"type\":  \( category)")
                var badge = 0
                if  let badgeCount = info["badge"] as? Int {
                    badge = badgeCount
                }
//                    print("\nFrom APS-dictionary with key \"type\":  \( badge)")
                    if category == NotificationCategoryMessages.NewChatMessage {
                        //refresh messages
//                        self.setChatBadgeCount(Int(badge))
//                        let navController = self.viewControllers![2] as! UINavigationController
//                        let chatTableViewController = navController.viewControllers[0] as! ChatTableViewController
////                        chatTableViewController.refresh()
//                        if chatTableViewController.view.window != nil {
//                            // viewController is visible
//                            NSUserDefaults.standardUserDefaults().setValue("isChatsCollectionShowing", forKey: "yes")
//                        } else {
//                            NSUserDefaults.standardUserDefaults().setValue("isChatsCollectionShowing", forKey: "no")
//                        }
//                        NSUserDefaults.standardUserDefaults().synchronize()
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchChatWithRecord(recordID)
                    }
                    else if category == NotificationCategoryMessages.NewOfferMessage {
                        if Int(badge) != 0{
                            self.setRequestBadgeCount(Int(badge))
                        }
                        //refresh Exchanges
                        let navController = self.viewControllers![3] as! UINavigationController
                        let requestsTableViewController = navController.viewControllers[0] as! RequestsTableViewController
                        if requestsTableViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
//                        requestsTableViewController.refresh()
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchExchangeWithRecord(recordID, message: NotificationCategoryMessages.NewOfferMessage)
                    }
                    else if category == NotificationCategoryMessages.ItemAdditionOrUpdation {
                        let navController = self.viewControllers![0] as! UINavigationController
                        let peruseViewController = navController.viewControllers[0] as! PeruseViewController
                        if peruseViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isPeruseShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isPeruseShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchItemWithRecord(recordID)
                    }
                    else if category == NotificationCategoryMessages.ItemDeletion {
                        let navController = self.viewControllers![0] as! UINavigationController
                        let peruseViewController = navController.viewControllers[0] as! PeruseViewController
                        if peruseViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isPeruseShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isPeruseShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
                        let recordID = info["recordID"] as! String
                        NSNotificationCenter.defaultCenter().postNotificationName("removeItemFromLocalDB", object: nil, userInfo: ["recordID":recordID])
                    }
                    else if category == NotificationCategoryMessages.UserStatusUpdate {
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchUserWithRecord(recordID)
                    }
                    else if category == NotificationCategoryMessages.UpdateOfferMessage {
                        var navController = self.viewControllers![3] as! UINavigationController
                        let requestsTableViewController = navController.viewControllers[0] as! RequestsTableViewController
                        if requestsTableViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
                        //                        requestsTableViewController.refresh()
                        
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        navController = self.viewControllers![2] as! UINavigationController
                        let chatTableViewController = navController.viewControllers[0] as! ChatTableViewController
                        if chatTableViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isChatsShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isChatsShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
                        //                        requestsTableViewController.refresh()
                        Model.sharedInstance().fetchExchangeWithRecord(recordID,message: NotificationCategoryMessages.UpdateOfferMessage)
                    }
                    else if category == NotificationCategoryMessages.AcceptedOfferMessage {
                        if Int(badge) != 0 {
                            self.setChatBadgeCount(Int(badge))
                        }
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchExchangeWithRecord(recordID, message: category)
                    }
//                }
                resetBadgeValue()
            }
        }
    }
    
    
    //MARK: - reset cloudkit badge value
    func resetBadgeValue() {
        setBadgeCounter(0)
    }
    //MARK: - reset cloudkit badge value
    func setBadgeCounter(count: Int) {
        let badgeOperation = CKModifyBadgeOperation(badgeValue: count)
        badgeOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                logw("Error resetting badge: \(error)")
            }
            else {
//                self.setRequestBadgeCount(0)
            }
        }
        CKContainer.defaultContainer().addOperation(badgeOperation)
    }
    
    func setRequestBadgeCount(count:Int) {
        if self.selectedIndex != 3 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![3]
                let currentRequestTabBadgeNumber: Int
                if requestTab.badgeValue == nil {
                    currentRequestTabBadgeNumber = 0
                } else {
                    currentRequestTabBadgeNumber = Int(requestTab.badgeValue!)!
                }
                requestTab.badgeValue = String(count + currentRequestTabBadgeNumber)
                UIApplication.sharedApplication().applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + count
            }
        }
    }
    
    func setChatBadgeCount(count:Int) {
        if self.selectedIndex != 2 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![2]
                let currentRequestTabBadgeNumber: Int
                if requestTab.badgeValue == nil {
                    currentRequestTabBadgeNumber = 0
                } else {
                    currentRequestTabBadgeNumber = Int(requestTab.badgeValue!)!
                }
                requestTab.badgeValue = String(count + currentRequestTabBadgeNumber)
                UIApplication.sharedApplication().applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + count
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
//                self.setBadgeCounter(<#T##count: Int##Int#>)
            }
        }
    }
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if item.tag == 2 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![2]
                let requestTabBadgeValue:Int
                if requestTab.badgeValue == nil {
                    requestTabBadgeValue = 0
                } else {
                    requestTabBadgeValue = Int(requestTab.badgeValue!)!
                }
                let number = UIApplication.sharedApplication().applicationIconBadgeNumber - requestTabBadgeValue
                requestTab.badgeValue = nil
                UIApplication.sharedApplication().applicationIconBadgeNumber = number
            }
        } else if item.tag == 3 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![3]
                let requestTabBadgeValue:Int
                if requestTab.badgeValue == nil {
                    requestTabBadgeValue = 0
                } else {
                    requestTabBadgeValue = Int(requestTab.badgeValue!)!
                }
                let number = UIApplication.sharedApplication().applicationIconBadgeNumber - requestTabBadgeValue
                requestTab.badgeValue = nil
                UIApplication.sharedApplication().applicationIconBadgeNumber = number
            }
        } else if item.tag == 4 {
            if let profileViewController = (self.viewControllers![4] as? UINavigationController)?.viewControllers[0] as? ProfileViewController {
                profileViewController.isShowingMyProfile = true
            }
        }
    }
}
