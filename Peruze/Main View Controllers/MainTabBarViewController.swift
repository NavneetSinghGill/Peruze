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
  override func viewDidAppear(animated: Bool) {
    Model.sharedInstance().getPeruzeItems(selectedViewController!, completion: {
      println("GetPeruzeItems completed!")
      dispatch_async(dispatch_get_main_queue()) {
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
      }
    })
  }
}
