//
//  GetPeruzeItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/16/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private enum GetPeruzeItemOperationError: ErrorType {
  case defaultError
}

class GetPeruzeItemOperation: GroupOperation {
  let context: NSManagedObjectContext
  let database: CKDatabase
  var cursor: CKQueryCursor?
  
  init(presentationContext: UIViewController,
    location: CLLocation?,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase) {
      self.context = context
      self.database = database
      var range = GetPeruzeItemOperation.userDistanceSettingInMeters()
      if location == nil {
        range = 0 //makes sure that the location is not accessed
      }
      var location = location ?? CLLocation() //makes sure that location is not nil
      let getItems = GetItemInRangeOperation(range: range, location: location, database: database, context: context)
      let fillMissingItemData = GetAllItemsWithMissingDataOperation(database: database, context: context)
      let fillMissingPeopleData = GetAllPersonsWithMissingData(database: database, context: context)
      
      //add dependencies
      fillMissingPeopleData.addDependency(fillMissingItemData)
      fillMissingItemData.addDependency(getItems)
      
      super.init(operations: [getItems, fillMissingItemData, fillMissingPeopleData])
  }
  
  //Convenience methods for retrieving the user's distance settings
  private class func userDistanceIsEverywhere() -> Bool {
    return userDistanceSettingInMi() == 25
  }
  private class func userDistanceSettingInMi() -> Int {
    return NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UsersDistancePreference) as? Int ?? 25
  }
  private class func userDistanceSettingInMeters() -> Float {
    return convertToKilometers(userDistanceSettingInMi()) * 1000
  }
  private class func convertToKilometers(miles: Int) -> Float {
    return Float(miles) * 1.60934
  }
  
}
