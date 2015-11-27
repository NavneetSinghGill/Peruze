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
            defaults.setObject("yes", forKey: "shouldCallWithSyncDate")
            defaults.synchronize()
        }
        if defaults.objectForKey("kCursor") == nil && defaults.boolForKey("keyIsMoreItemsAvalable") == false {
            defaults.setObject("yes", forKey: "shouldCallWithSyncDate")
        }
        print("\n\n\(NSDate())===== GroupOperation Start======")
      getItems = GetItemInRangeOperation(range: range, location: location, cursor: cursor, database: database, context: context, resultLimit: 10)
        getItems.completionBlock = {
            print("\n\n\(NSDate())===== GetItemInRangeOperation Comp======")
        }
        
        
      let fillMissingItemData = GetAllItemsWithMissingDataOperation(database: database, context: context)
        fillMissingItemData.completionBlock = {
            print("\n\n\(NSDate())===== fillMissingItemData Comp======")
        }
//      let fillMissingPeopleData = GetAllPersonsWithMissingData(database: database, context: context)
//        fillMissingPeopleData.completionBlock = {
//            print("\n\n\(NSDate())===== fillMissingPeopleData Comp======")
//        }
      
      //add dependencies
//      fillMissingPeopleData.addDependency(getItems)
      fillMissingItemData.addDependency(getItems)
      
      super.init(operations: [getItems, fillMissingItemData])
    }
  override func finished(errors: [NSError]) {
    print("\n\n\(NSDate())===== GroupOperation Comp======")
    let defaults = NSUserDefaults.standardUserDefaults()
    if defaults.objectForKey("shouldCallWithSyncDate") != nil && defaults.objectForKey("shouldCallWithSyncDate") as! String == "yes" {
        defaults.setObject("no", forKey: "shouldCallWithSyncDate")
    }
    if (getItems.cursor != nil){
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(getItems.cursor!)
        defaults.setObject(encodedData, forKey: "kCursor")
    } else {
        defaults.removeObjectForKey("kCursor")
        defaults.setBool(false, forKey: "keyIsMoreItemsAvalable")
        defaults.synchronize()
    }
    defaults.synchronize()
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
  public class func userDistanceSettingInMeters() -> Float {
    return convertToKilometers(userDistanceSettingInMi()) * 1000
  }
  private class func convertToKilometers(miles: Int) -> Float {
    return Float(miles) * 1.60934
  }
  
}
