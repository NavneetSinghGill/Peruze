//
//  GetItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import SwiftLog

private let logging = true
private var resultsLimit = 100 //the limit for the results from the server. The lower this is, the faster the speed :)

class GetItemInRangeOperation: GetItemOperation {
  var range: Float
  let location: CLLocation
  ///If range is 0, then will retrieve all items
  init(range: Float,
    location: CLLocation,
    cursor: CKQueryCursor?,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    resultLimit : Int) {
      if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
      
      self.range = range
      self.location = location
      
        super.init(cursor: cursor, database: database, context: context, resultLimit : resultLimit)
      
      let networkObserver = NetworkObserver()
      addObserver(networkObserver)
  }

    
//   override func getPredicate() -> NSPredicate {
//        return NSPredicate(value: true)
//    }
    
    override func getPredicate() -> NSPredicate {
        logw("\n \(NSDate()) GetItemInRangeOperation getPredicate()")
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let myRecordID = CKRecordID(recordName: (me.valueForKey("recordIDName") as! String))
        
        range = 1.60934 * 1000 * 25 //everywhere range is 25 miles
        
//        let locationPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
//              "Location",
//              location,
//              range)
        
        //            var compoundPredicate: NSCompoundPredicate?
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey("shouldCallWithSyncDate") as? String != nil && defaults.objectForKey("shouldCallWithSyncDate") as! String == "yes" {
            var datePredicate = NSPredicate(format: "modificationDate > %@", NSDate())
            if let date = defaults.objectForKey("syncDate") as? NSDate {
                datePredicate = NSPredicate(format: "modificationDate > %@", date)
            }
            let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myRecordID)
            defaults.setObject("no", forKey: "shouldCallWithSyncDate")
            return NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate,notMyItemsPredicate])
        } else {
            let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myRecordID)
            return NSCompoundPredicate(andPredicateWithSubpredicates: [notMyItemsPredicate])
        }
    }
  
//  override func getPredicate() -> NSPredicate {
//    if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
//    
//    //create predicates
//    let me = Person.MR_findFirstByAttribute("me", withValue: true)
//    let myRecordID = CKRecordID(recordName: (me.valueForKey("recordIDName") as! String))
//    
//    var compoundPredicate: NSCompoundPredicate?
//    let defaults = NSUserDefaults.standardUserDefaults()
//    if defaults.objectForKey("shouldCallWithSyncDate") as? String != nil && defaults.objectForKey("shouldCallWithSyncDate") as! String == "yes" {
//        var datePredicate = NSPredicate(format: "modificationDate > %@", NSDate())
//        if let date = defaults.objectForKey("syncDate") as? NSDate {
//            datePredicate = NSPredicate(format: "modificationDate > %@", date)
//        }
//        let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myRecordID)
//        compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate,notMyItemsPredicate])
//        defaults.setObject("no", forKey: "shouldCallWithSyncDate")
//    } else {
//        let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myRecordID)
//        compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notMyItemsPredicate])
//    }
//    
//    let everywhereLocation = NSPredicate(value: true)
//    let specificLocation = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
//      "Location",
//      location,
//      range)
//    
//    //choose and concatenate predicates
//    let locationPredicate = ((range == 0) ? everywhereLocation : specificLocation)
//    
//    var friendPredicate = NSPredicate!()
//    let userPrivacySetting = Model.sharedInstance().userPrivacySetting()
//    if userPrivacySetting == FriendsPrivacy.Friends {
//        let friendsIds : NSArray = defaults.objectForKey("kFriends") as! NSArray
//        friendPredicate = NSPredicate(format: "OwnerFacebookID IN %@", friendsIds)
//        return NSCompoundPredicate(andPredicateWithSubpredicates:[locationPredicate, compoundPredicate!, friendPredicate])
//    } else if userPrivacySetting == FriendsPrivacy.FriendsOfFriends{
//        if let friendsIds : NSArray = defaults.objectForKey("kFriendsOfFriend") as? NSArray {
//            friendPredicate = NSPredicate(format: "OwnerFacebookID IN %@", friendsIds)
//            return NSCompoundPredicate(andPredicateWithSubpredicates: [locationPredicate, compoundPredicate!, friendPredicate])
//        }
//        return NSPredicate(value: true)
//    } else {
//        return NSCompoundPredicate(andPredicateWithSubpredicates: [locationPredicate, compoundPredicate!])
//    }
//  }
}

class GetItemOperation: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  var cursor: CKQueryCursor?
  var hasDataRetrivedFromCloud = false
  init(cursor: CKQueryCursor? = nil,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    resultLimit : Int) {
      if logging { logw("GetItemOperation " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
      self.cursor = cursor
      self.database = database
      self.context = context
    resultsLimit = resultLimit
      super.init()
  }
  override func finished(errors: [NSError]) {
    if logging { logw("GetItemOperation " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    if errors.first != nil {
      logw("\(errors.first)")
    }
  }
  
  override func execute() {
    if logging { logw("\n\(NSDate())\nExecute GetItemOperation " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    //create operation for fetching relevant records
    var getItemsOperation: CKQueryOperation
    if let cursor = cursor {
      getItemsOperation = CKQueryOperation(cursor: cursor)
    } else {
    let predicate = getPredicate()
        if logging { logw("\n\(NSDate())\n Predicate for get Items::: \(predicate)") }
      let getItemQuery = CKQuery(recordType: RecordTypes.Item, predicate: predicate/* NSPredicate(value: true)*/)
      getItemsOperation = CKQueryOperation(query: getItemQuery)
    }
    
    getItemsOperation.desiredKeys = ["Description","ImageUrl","IsDeleted","Location","OwnerFacebookID","Title"]
    
    getItemsOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in
        self.hasDataRetrivedFromCloud = true
      if logging { logw("\(NSDate())\nGetItemsOperation per record completion block \n \(record)") }
      
      let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
        
      localUpload.setValue(record.recordID.recordName, forKey: "recordIDName")
      
      let ownerRecordIDName = record.creatorUserRecordID!.recordName
      
      if ownerRecordIDName == "__defaultOwner__" {
        let owner = Person.MR_findFirstByAttribute("me",
          withValue: true,
          inContext: self.context)
        localUpload.setValue(owner, forKey: "owner")
      } else {
        if let owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: ownerRecordIDName,
            inContext: self.context){
        localUpload.setValue(owner, forKey: "owner")
        }
      }
        
        if let imageUrlSuffix = record.objectForKey("ImageUrl") as? String {
            localUpload.setValue(imageUrlSuffix, forKey: "imageUrl")
            
//            //download image
//            let downloadingFilePath = NSTemporaryDirectory()
//            let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrlSuffix, downloadingFilePath: downloadingFilePath)
//            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//            let task = transferManager.download(downloadRequest)
//            task.continueWithBlock({ (task) -> AnyObject? in
//                if task.error != nil {
//                    logw("GetItemOperation image download failed with error: \(task.error!)")
//                } else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        let fileUrl = task.result!.valueForKey("body")!
//                        let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                        localUpload.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                        self.context.MR_saveToPersistentStoreAndWait()
//                    }
//                }
//                return nil
//            })
    }
        
      if let title = record.objectForKey("Title") as? String {
        localUpload.setValue(title, forKey: "title")
      }
      
      if let detail = record.objectForKey("Description") as? String {
        localUpload.setValue(detail, forKey: "detail")
      }
      
      if let ownerFacebookID = record.objectForKey("OwnerFacebookID") as? String {
        localUpload.setValue(ownerFacebookID, forKey: "ownerFacebookID")
      } else {
        localUpload.setValue("noId", forKey: "ownerFacebookID")
      }
      
//      if let imageAsset = record.objectForKey("Image") as? CKAsset {
//        let imageData = NSData(contentsOfURL: imageAsset.fileURL)
//        localUpload.setValue(imageData, forKey: "image")
//      }
               
        if let itemLocation = record.objectForKey("Location") as? CLLocation {//(latitude: itemLat.doubleValue, longitude: itemLong.doubleValue)
            
            if let latitude : Double = Double(itemLocation.coordinate.latitude) {
                localUpload.setValue(latitude, forKey: "latitude")
            }
            
            if let longitude : Double = Double(itemLocation.coordinate.longitude) {
                localUpload.setValue(longitude, forKey: "longitude")
            }
        }
        
        if let isDelete = record.objectForKey("IsDeleted") as? Int {
            localUpload.setValue(isDelete, forKey: "isDelete")
        }
        
        localUpload.setValue(NSDate(), forKey: "dateOfDownload")
        
        if localUpload.hasRequested != "yes" {
            localUpload.setValue("no", forKey: "hasRequested")
        }
        
      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    getItemsOperation.queryCompletionBlock = { (cursor, error) -> Void in
        let date = NSDate()
        NSUserDefaults.standardUserDefaults().setObject(date, forKey: "syncDate")
      if let error = error {
        logw("Get Uploads Finished With Error: \(error) ")
        self.finishWithError(error)
      } else {
        self.cursor = cursor
        self.finish()
      }
    }
    
    //add that operation to the operationQueue of self.database
    getItemsOperation.qualityOfService = qualityOfService
    getItemsOperation.resultsLimit = resultsLimit
    self.database.addOperation(getItemsOperation)
  }
  
  func getPredicate() -> NSPredicate {
    return NSPredicate(value: false)
  }
  
}


class GetAllItemsWithMissingDataOperation: Operation {
  
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    if logging { logw("GetAllItemsWithMissingDataOperation " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    if logging { logw("\n\n\(NSDate()) GetAllItemsWithMissingDataOperation " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    let allItemsPredicate = NSPredicate(format: "recordIDName != nil AND imageUrl == nil")
    
    let allItems = Item.MR_findAllWithPredicate(allItemsPredicate, inContext: context) as! [NSManagedObject]
    
    if logging { logw("\n\n\(NSDate()) MissingItemsDataCount : \( allItems.count)") }
    
    let allRecordIDNames = allItems.map { $0.valueForKey("recordIDName") as? String }
    
    var itemRecordsToFetch = [CKRecordID]()
    
    for itemRecordIDName in allRecordIDNames {
      if itemRecordIDName != nil {
        itemRecordsToFetch.append(CKRecordID(recordName: itemRecordIDName!))
      }
    }
    
    let fetchAllItemsOperation = CKFetchRecordsOperation(recordIDs: itemRecordsToFetch)
    fetchAllItemsOperation.desiredKeys = ["Description","ImageUrl","IsDeleted","Location","OwnerFacebookID","Title"]
    fetchAllItemsOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
    if logging { logw("\n\n\(NSDate()) GetAllItemsWithMissing DataOperation Per record " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
        
      guard let recordsByID = recordsByID else {
        self.finishWithError(error)
        return
      }
      
      //for each record that is returned
      for recordID in recordsByID.keys {
        guard let record = recordsByID[recordID] else {
          logw("A record in GetItemOperation was nil")
          continue
        }
        //get a local copy of the item to save
        let localItem = Item.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: recordID.recordName,
          inContext: self.context)
        
        //get image
//        if let image = record.valueForKey("Image") as? CKAsset {
//          let imageData = NSData(contentsOfURL: image.fileURL)
//          localItem.setValue(imageData, forKey: "image")
//        } else {
//          logw("Image is not a CKAsset")
//        }
        // get image
        if let imageUrlSuffix = record.objectForKey("ImageUrl") as? String {
            localItem.setValue(imageUrlSuffix, forKey: "imageUrl")
            
            //download image
//            let downloadingFilePath = NSTemporaryDirectory()
//            let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrlSuffix, downloadingFilePath: downloadingFilePath)
//            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//            let task = transferManager.download(downloadRequest)
//            task.continueWithBlock({ (task) -> AnyObject? in
//                if task.error != nil {
//                    logw("GetItemOperation image download failed with error: \(task.error)")
//                } else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        let fileUrl = task.result!.valueForKey("body")!
//                        let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                        localItem.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                        self.context.MR_saveToPersistentStoreAndWait()
//                    }
//                }
//                return nil
//            })
        }
        
        //get title
        if let title = record.valueForKey("Title") as? String {
          localItem.setValue(title, forKey: "title")
        } else {
          logw("Title is not a String")
        }
        
        
        //get detail
        if let detail = record.valueForKey("Description") as? String {
          localItem.setValue(detail, forKey: "detail")
        } else {
          logw("Description is not a String")
        }
        
        if let isDelete = record.objectForKey("IsDeleted") as? Int {
            localItem.setValue(isDelete, forKey: "isDelete")
        }
        
        //fill in creator details
        var creatorIDName = record.creatorUserRecordID!.recordName
        
        if creatorIDName == "__defaultOwner__"{
            creatorIDName = Person.MR_findFirstByAttribute("me", withValue: true).valueForKey("recordIDName") as! String
        }
        let localOwner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: creatorIDName,
          inContext: self.context)
        localItem.setValue(localOwner, forKey: "owner")
        
        if let facebookID = record.valueForKey("OwnerFacebookID") as? String {
          localOwner.setValue(facebookID, forKey: "facebookID")
        } else {
            localOwner.setValue("noId", forKey: "facebookID")
        }
        
        localItem.setValue(NSDate(), forKey: "dateOfDownload")
        
        self.context.MR_saveToPersistentStoreAndWait()

      }
      self.finish()
    }
    fetchAllItemsOperation.qualityOfService = qualityOfService
    database.addOperation(fetchAllItemsOperation)
  }
}