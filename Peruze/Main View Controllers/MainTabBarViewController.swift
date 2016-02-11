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
    resetBadgeValue()
  }
  //GO HERE
  let manager = CLLocationManager()
  override func viewDidAppear(animated: Bool) {
    manager.requestWhenInUseAuthorization()
    setInitialBadge()
  }
    
    func setInitialBadge() {
        let requestTab = self.tabBar.items![2]
        let requestTabBadgeValue:Int
        if requestTab.badgeValue == nil {
            requestTabBadgeValue = 0
        } else {
            requestTabBadgeValue = Int(requestTab.badgeValue!)!
        }
        
        let chatTab = self.tabBar.items![3]
        let chatTabBadgeValue:Int
        if chatTab.badgeValue == nil {
            chatTabBadgeValue = 0
        } else {
            chatTabBadgeValue = Int(chatTab.badgeValue!)!
        }
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = chatTabBadgeValue + requestTabBadgeValue
    }
    
    //MARK: - Private methods

    func registerNotifications() {
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "showTabBar:",name:"showIniticiaViewController",object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "showBadgeOnRequestTab:",name:"ShowBadgeOnRequestTab",object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self,selector: "resetBadgeValue",name:"ResetBadgeValue",object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "setApplicationBadgeCount", name: "applicationDidBecomeActive", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "setRequestBadgeCount:", name: "setRequestBadge", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "setChatBadgeCount:", name: "setAcceptedExchangesBadge", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showChatScreen", name: NotificationCenterKeys.LNAcceptedRequest, object: nil)
    }
    func showTabBar(notification: NSNotification){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func showBadgeOnRequestTab(notification: NSNotification){
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if notification.userInfo != nil{
            let info : NSDictionary = notification.userInfo!
            if  let category = info["category"] as? String {
                // Printout of (userInfo["aps"])["type"]
                logw("\nMainTabbarVC From APS-dictionary with key \"type\":  \( category)")
                var badge = 0
                if  let badgeCount = info["badge"] as? Int {
                    badge = badgeCount
                }
                    if category == NotificationCategoryMessages.NewChatMessage {
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchChatWithRecord(recordID, badgeCount: Int(badge))
                    }
                    else if category == NotificationCategoryMessages.NewOfferMessage {
                        let navController = self.viewControllers![3] as! UINavigationController
                        let requestsTableViewController = navController.viewControllers[0] as! RequestsTableViewController
                        if requestsTableViewController.view.window != nil {
                            // viewController is visible
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "yes")
                        } else {
                            NSUserDefaults.standardUserDefaults().setValue("isRequestsShowing", forKey: "no")
                        }
                        NSUserDefaults.standardUserDefaults().synchronize()
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchExchangeWithRecord(recordID, message: NotificationCategoryMessages.NewOfferMessage, badgeCount: Int(badge))
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
                        Model.sharedInstance().fetchItemWithRecord(recordID, shouldReloadScreen: false)
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
                        Model.sharedInstance().fetchExchangeWithRecord(recordID,message: NotificationCategoryMessages.UpdateOfferMessage)
                    }
                    else if category == NotificationCategoryMessages.AcceptedOfferMessage {
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchExchangeWithRecord(recordID, message: category, badgeCount: Int(badge))
                    } else if category == NotificationCategoryMessages.NewReview {
                        let recordID = CKRecordID(recordName: info["recordID"] as! String)
                        Model.sharedInstance().fetchReviewWithRecord(recordID)
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
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with count \(count)")
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
    
    func setRequestBadgeCount(notification: NSNotification) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if notification.userInfo == nil {
            return
        }
        if notification.userInfo != nil {
            let userInfo : NSDictionary = notification.userInfo!
            let count = userInfo.valueForKey("badgeCount") as! Int
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
                    
                    let chatTab = self.tabBar.items![2]
                    let currentChatTabBadgeNumber: Int
                    if chatTab.badgeValue == nil {
                        currentChatTabBadgeNumber = 0
                    } else {
                        currentChatTabBadgeNumber = Int(chatTab.badgeValue!)!
                    }
                    //                if NSUserDefaults.standardUserDefaults().boolForKey("isAppActive") == true {
                    UIApplication.sharedApplication().applicationIconBadgeNumber = -1
                    UIApplication.sharedApplication().applicationIconBadgeNumber = currentChatTabBadgeNumber + count + currentRequestTabBadgeNumber
                    //                }
                }
            }
        }
    }
    
    func setChatBadgeCount(notification: NSNotification) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if notification.userInfo == nil {
            return
        }
        if notification.userInfo != nil {
            let userInfo : NSDictionary = notification.userInfo!
            let count = userInfo.valueForKey("badgeCount") as! Int
            if self.selectedIndex != 2 {
                dispatch_async(dispatch_get_main_queue()) {
                    let chatTab = self.tabBar.items![2]
                    let currentChatTabBadgeNumber: Int
                    if chatTab.badgeValue == nil {
                        currentChatTabBadgeNumber = 0
                    } else {
                        currentChatTabBadgeNumber = Int(chatTab.badgeValue!)!
                    }
                    chatTab.badgeValue = String(count + currentChatTabBadgeNumber)
                    
                    let requestTab = self.tabBar.items![3]
                    let currentRequestTabBadgeNumber: Int
                    if requestTab.badgeValue == nil {
                        currentRequestTabBadgeNumber = 0
                    } else {
                        currentRequestTabBadgeNumber = Int(requestTab.badgeValue!)!
                    }
                    
                    //                if NSUserDefaults.standardUserDefaults().boolForKey("isAppActive") == true {
                    UIApplication.sharedApplication().applicationIconBadgeNumber = -1
                    UIApplication.sharedApplication().applicationIconBadgeNumber = currentRequestTabBadgeNumber + count + currentChatTabBadgeNumber
                    //                }
                }
            }
        }
    }
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with tag: \(item.tag)")
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
    
    func setApplicationBadgeCount() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let requestTab = self.tabBar.items![3]
        let currentRequestTabBadgeNumber: Int
        if requestTab.badgeValue == nil {
            currentRequestTabBadgeNumber = 0
        } else {
            currentRequestTabBadgeNumber = Int(requestTab.badgeValue!)!
        }
        
        let chatTab = self.tabBar.items![2]
        let currentChatTabBadgeNumber: Int
        if chatTab.badgeValue == nil {
            currentChatTabBadgeNumber = 0
        } else {
            currentChatTabBadgeNumber = Int(chatTab.badgeValue!)!
        }
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = currentRequestTabBadgeNumber + currentChatTabBadgeNumber
    }
    
    //MARK: Notification method
    
    func showChatScreen() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.selectedIndex = 2
    }
}
