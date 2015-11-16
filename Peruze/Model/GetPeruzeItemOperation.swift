//
//  GetPeruzeItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/16/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private let logging = true

private enum GetPeruzeItemOperationError: ErrorType {
  case defaultError
}

class GetPeruzeItemOperation: GroupOperation {
  let presentationContext: UIViewController
  let getItems: GetItemOperation
  var cursor: CKQueryCursor?
  
  init(presentationContext: UIViewController,
    location: CLLocation?,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase) {
      if logging { print(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
      self.presentationContext = presentationContext
      var range = GetPeruzeItemOperation.userDistanceSettingInMeters()
      if location == nil {
        range = 0 //makes sure that the location is not accessed
      }
      let location = location ?? CLLocation() //makes sure that location is not nil
        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.objectForKey("kCursor") != nil){
            let decoded  = defaults.objectForKey("kCursor") as! NSData
            let decodedTeams = NSKeyedUnarchiver.unarchiveObjectWithData(decoded) as! CKQueryCursor
            cursor = decodedTeams
            defaults.synchronize()
        }
      getItems = GetItemInRangeOperation(range: range, location: location, cursor: cursor, database: database, context: context)
      let fillMissingItemData = GetAllItemsWithMissingDataOperation(database: database, context: context)
//      let fillMissingPeopleData = GetAllPersonsWithMissingData(database: database, context: context)
      
      //add dependencies
//      fillMissingPeopleData.addDependency(fillMissingItemData)
      fillMissingItemData.addDependency(getItems)
      
      super.init(operations: [getItems])//, fillMissingItemData, fillMissingPeopleData])
    }
  override func finished(errors: [NSError]) {
    if (getItems.cursor != nil){
        let defaults = NSUserDefaults.standardUserDefaults()
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(getItems.cursor!)
        defaults.setObject(encodedData, forKey: "kCursor")
        defaults.synchronize()
    }
    cursor = getItems.cursor
    if let error = errors.first {
      print(error)
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "Oops!"
      alert.message = "There was an error trying to retrieve items from the iCloud server. Please try again."
      produceOperation(alert)
    }
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
