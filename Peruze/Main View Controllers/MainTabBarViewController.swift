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
      context: managedConcurrentObjectContext)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let fetchMissingItems = GetAllItemsWithMissingDataOperation(database: publicDB)
    let fetchMissingPeople = GetAllPersonsWithMissingData(database: publicDB)
    fetchMissingItems.addDependency(getItemsOperation)
    fetchMissingPeople.addDependency(fetchMissingItems)
    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = NSQualityOfService.Utility
    operationQueue.addOperations([getItemsOperation, fetchMissingItems, fetchMissingPeople], waitUntilFinished: false)
  }
}
