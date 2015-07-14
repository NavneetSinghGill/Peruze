//
//  MainTabBarViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/7/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {
  override func viewDidLoad() {
    super.viewDidLoad()
    tabBar.tintColor = UIColor.redColor()
    Model.sharedInstance().fetchMyProfileWithCompletion() { error -> Void in
      if Model.sharedInstance().locationManager.location != nil {
        Model.sharedInstance().updateUserLocation(Model.sharedInstance().locationManager.location)
      }
    }
  }
}
