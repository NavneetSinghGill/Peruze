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
    
  }
  let manager = CLLocationManager()
  override func viewDidAppear(animated: Bool) {
    manager.requestWhenInUseAuthorization()
    Model.sharedInstance().getPeruzeItems(selectedViewController!, completion: {
      print("GetPeruzeItems completed!")
      dispatch_async(dispatch_get_main_queue()) {
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
      }
    })
  }
}
