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

class GetItemInRangeOperation: GetItemOperation {
  let range: Float?
  let location: CLLocation
  ///If range is nil, then will retrieve all items
  init(range: Float? = nil, location: CLLocation, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.range = range
    self.location = location
    
    super.init(database: database, context: context)
    
    let locationCondition = LocationCondition(usage: LocationCondition.Usage.Always, manager: nil)
    addCondition(locationCondition)
    
    let networkObserver = NetworkObserver()
    addObserver(networkObserver)
  }
  
  override func getPredicate() -> NSPredicate {
    
    //create predicates
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let myRecordID = CKRecordID(recordName: (me.valueForKey("recordIDName") as! String))
    let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myRecordID)
    let everywhereLocation = NSPredicate(value: true)
    let specificLocation = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
      "Location",
      location,
      (range ?? 0))
    
    //choose and concatenate predicates
    let locationPredicate = ((range == nil) ? everywhereLocation : specificLocation)
    let othersInRange = NSCompoundPredicate.andPredicateWithSubpredicates([locationPredicate, notMyItemsPredicate])
    return othersInRange
  }
}

class GetItemOperation: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  
  override func finished(errors: [ErrorType]) {
    if errors.first != nil {
      println(errors.first)
    }
  }
  
  override func execute() {    
    //create operation for fetching relevant records
    var resultsLimit = 10
    let getItemQuery = CKQuery(recordType: RecordTypes.Item, predicate: getPredicate())
    let getItemsOperation = CKQueryOperation(query: getItemQuery)
    
    getItemsOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in
      
      let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      localUpload.setValue(record.recordID.recordName, forKey: "recordIDName")
      
      let ownerRecordIDName = record.creatorUserRecordID.recordName
      
      if ownerRecordIDName == "__defaultOwner__" {
        let owner = Person.MR_findFirstByAttribute("me",
          withValue: true,
          inContext: self.context)
        localUpload.setValue(owner, forKey: "owner")
      } else {
        let owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: ownerRecordIDName,
          inContext: self.context)
        localUpload.setValue(owner, forKey: "owner")
      }
      
      if let title = record.objectForKey("Title") as? String {
        localUpload.setValue(title, forKey: "title")
      }
      
      if let detail = record.objectForKey("Description") as? String {
        localUpload.setValue(detail, forKey: "detail")
      }
      
      if let ownerFacebookID = record.objectForKey("OwnerFacebookID") as? String {
        localUpload.setValue(ownerFacebookID, forKey: "ownerFacebookID")
      }
      
      if let imageAsset = record.objectForKey("Image") as? CKAsset {
        let imageData = NSData(contentsOfURL: imageAsset.fileURL)
        localUpload.setValue(imageData, forKey: "image")
      }
      
      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
      
    }
    
    getItemsOperation.queryCompletionBlock = { (cursor, error) -> Void in
      if error != nil { print("Get Uploads Finished With Error: \(error)") }
      self.finish(GenericError.ExecutionFailed)
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
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    print("execute item fetch")
    
    let allItemsPredicate = NSPredicate(format: "recordIDName != nil AND image == nil")
    
    let allItems = Item.MR_findAllWithPredicate(allItemsPredicate, inContext: context) as! [NSManagedObject]
    
    let allRecordIDNames = allItems.map { $0.valueForKey("recordIDName") as? String }
    
    var itemRecordsToFetch = [CKRecordID]()
    
    for itemRecordIDName in allRecordIDNames {
      if itemRecordIDName != nil {
        itemRecordsToFetch.append(CKRecordID(recordName: itemRecordIDName!))
      }
    }
    
    let fetchAllItemsOperation = CKFetchRecordsOperation(recordIDs: itemRecordsToFetch)
    fetchAllItemsOperation.fetchRecordsCompletionBlock = { (recordsByID: [NSObject: AnyObject]!, error: NSError!) -> Void in
      
      //for each record that is returned
      for recordID in recordsByID.keys.array {
        let recordID = recordID as! CKRecordID
        let record = recordsByID[recordID] as! CKRecord
        //get a local copy of the item to save
        let localItem = Item.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: recordID.recordName,
          inContext: self.context)
        
        //get image
        if let image = record.valueForKey("Image") as? CKAsset {
          let imageData = NSData(contentsOfURL: image.fileURL)
          localItem.setValue(imageData, forKey: "image")
        } else {
          print("Image is not a CKAsset")
        }
        
        //get title
        if let title = record.valueForKey("Title") as? String {
          localItem.setValue(title, forKey: "title")
        } else {
          print("Title is not a String")
        }
        
        
        //get detail
        if let detail = record.valueForKey("Description") as? String {
          localItem.setValue(detail, forKey: "detail")
        } else {
          print("Description is not a String")
        }
        
        
        //fill in creator details
        let creatorIDName = record.creatorUserRecordID.recordName
        
        let localOwner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: creatorIDName,
          inContext: self.context)
        localItem.setValue(localOwner, forKey: "owner")
        
        if let facebookID = record.valueForKey("OwnerFacebookID") as? String {
          localOwner.setValue(facebookID, forKey: "facebookID")
        }
        
        self.context.MR_saveToPersistentStoreAndWait()
      }
      self.finish(GenericError.ExecutionFailed)
    }
    fetchAllItemsOperation.qualityOfService = qualityOfService
    database.addOperation(fetchAllItemsOperation)
  }
}