//
//  MainTabBarViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/7/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit

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
//    NSNotificationCenter.defaultCenter().addObserver(self,selector: "showBadgeOnRequestTab:",name:"ShowBadgeOnRequestTab",object: nil)
//    NSNotificationCenter.defaultCenter().addObserver(self,selector: "resetBadgeValue",name:"ResetBadgeValue",object: nil)
    }
    func showTabBar(notification: NSNotification){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func showBadgeOnRequestTab(notification: NSNotification){
        let info : NSDictionary = notification.userInfo!
        
        if  let alert = info["alert"] as? String {
            // Printout of (userInfo["aps"])["type"]
            print("\nFrom APS-dictionary with key \"type\":  \( alert)")
            if  let badge = info["badge"] as? Int {
                print("\nFrom APS-dictionary with key \"type\":  \( badge)")
                if alert == NotificationMessages.NewChatMessage {
                    //refresh messages
                    self.setChatBadgeCount(Int(badge))
                    let controller = self.viewControllers![2] as! ChatTableViewController
                    controller.refresh()
                } else if alert == NotificationMessages.NewOfferMessage {
                    self.setRequestBadgeCount(Int(badge))
                    //refresh Exchanges
                    let controller = self.viewControllers![3] as! RequestsTableViewController
                    controller.refresh()
                }
            }
        }
    }
    
    
    //MARK: - reset cloudkit badge value
    func resetBadgeValue() {
        resetBadgeCounter()
    }
    //MARK: - reset cloudkit badge value
    func resetBadgeCounter() {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: 0)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print("Error resetting badge: \(error)")
            }
            else {
                self.setRequestBadgeCount(0)
            }
        }
        CKContainer.defaultContainer().addOperation(badgeResetOperation)
    }
    
    func setRequestBadgeCount(count:Int) {
        if self.selectedIndex != 3 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![3]
                requestTab.badgeValue = String(count)
                UIApplication.sharedApplication().applicationIconBadgeNumber = count
            }
        }
    }
    
    func setChatBadgeCount(count:Int) {
        if self.selectedIndex != 2 {
            dispatch_async(dispatch_get_main_queue()) {
                let requestTab = self.tabBar.items![2]
                requestTab.badgeValue = String(count)
                UIApplication.sharedApplication().applicationIconBadgeNumber = count
            }
        }
    }
}
