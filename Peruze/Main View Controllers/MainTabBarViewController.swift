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
    }
    func showTabBar(notification: NSNotification){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}
