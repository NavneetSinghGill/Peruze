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
    let getItemsOperation = GetItemInRangeOperation(
      range: nil,
      location: CLLocation(),
      database: CKContainer.defaultContainer().publicCloudDatabase,
      context: managedMainObjectContext)
    OperationQueue().addOperation(getItemsOperation)
  }
}
