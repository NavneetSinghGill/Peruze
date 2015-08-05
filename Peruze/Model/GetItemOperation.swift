//
//  GetItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import MagicalRecord
import CloudKit

class GetItemInRangeOperation: GetItemOperation {
  let range: Float?
  let location: CLLocation
  ///If range is nil, then will retrieve all items
  init(range: Float? = nil, location: CLLocation, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.range = range
    self.location = location
    super.init(database: database, context: context)
  }
  
  override func getPredicate() -> NSPredicate {
    
    //create predicates
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", CKRecordID(recordName: me.recordIDName!))
    let everywhereLocation = NSPredicate(value: true)
    let specificLocation = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
      "Location",
      location,
      range ?? 0)
    
    //choose and concatenate predicates
    let locationPredicate = range == nil ? everywhereLocation : specificLocation
    let othersInRange = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [locationPredicate, notMyItemsPredicate])
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
  override func finished(errors: [NSError]) {
    NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
  }
  override func execute() {
    print("Hit " + __FUNCTION__ + " in " + __FILE__)
    
    //create operation for fetching relevant records
    let getItemQuery = CKQuery(recordType: RecordTypes.Item, predicate: getPredicate())
    let getItemsOperation = CKQueryOperation(query: getItemQuery)
    
    getItemsOperation.recordFetchedBlock = { (record) -> Void in
      print(record)
      
      
      let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      localUpload.recordIDName = record.recordID.recordName
      
      if let ownerRecordIDName = record.creatorUserRecordID?.recordName {
        
        if ownerRecordIDName == "__defaultOwner__" {
          localUpload.owner = Person.MR_findFirstOrCreateByAttribute("me",
            withValue: true,
            inContext: self.context)
        } else {
          localUpload.owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: ownerRecordIDName,
            inContext: self.context)
        }
        
        if let title = record.objectForKey("Title") as? String {
          localUpload.title = title
        }
        
        if let detail = record.objectForKey("Description") as? String {
          localUpload.detail = detail
        }
        
        if let ownerFacebookID = record.objectForKey("OwnerFacebookID") as? String {
          localUpload.ownerFacebookID = ownerFacebookID
        }
        
        if let imageAsset = record.objectForKey("Image") as? CKAsset {
          localUpload.image = NSData(contentsOfURL: imageAsset.fileURL)
        }
        
        //save the context
        self.context.MR_saveToPersistentStoreAndWait()
      }
    }
    
    getItemsOperation.queryCompletionBlock = { (cursor, error) -> Void in
      if error != nil { print("Get Uploads Finished With Error: \(error)") }
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
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
    //Swift 2.0
    //    guard let allItems = Item.MR_findAllWithPredicate(allItemsPredicate, inContext: context) as? [NSManagedObject] else {
    //      print("Get Item Operation could not cast returned objects as [NSManagedObject]")
    //      self.finish()
    //      return
    //    }
    let allItems = Item.MR_findAllWithPredicate(allItemsPredicate, inContext: context) as! [NSManagedObject]
    
    let allRecordIDNames = allItems.map { $0.valueForKey("recordIDName") as? String }
    
    var itemRecordsToFetch = [CKRecordID]()
    //Swift 2.0
    //for itemRecordIDName in allRecordIDNames where itemRecordIDName != nil {
    for itemRecordIDName in allRecordIDNames{
      if itemRecordIDName != nil {
        itemRecordsToFetch.append(CKRecordID(recordName: itemRecordIDName!))
      }
    }
    
    let fetchAllItemsOperation = CKFetchRecordsOperation(recordIDs: itemRecordsToFetch)
    fetchAllItemsOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      if error != nil {
        print("FETCH ALL ITEMS RETURNED ERROR: \(error)")
      }
      //make sure the recordsByID are not nil
      if let recordsByID = recordsByID {
        
        
        //for each record that is returned
        for recordID in recordsByID.keys {
          let recordID = recordID as! CKRecordID
          //get a local copy of the item to save
          let localItem = Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: recordID.recordName,
            inContext: self.context)
          
          //get image
          if let image = recordsByID[recordID]!.valueForKey("Image") as? CKAsset {
            localItem.image = NSData(contentsOfURL: image.fileURL)
          } else {
            print("Image is not a CKAsset")
          }
          
          //get title
          if let title = recordsByID[recordID]!.valueForKey("Title") as? String {
            localItem.setValue(title, forKey: "title")
          } else {
            print("Title is not a String")
          }
          
          
          //get detail
          if let description = recordsByID[recordID]!.valueForKey("Description") as? String {
            localItem.detail = description
          } else {
            print("Description is not a String")
          }
          
          
          //fill in creator details
          if let creator = recordsByID[recordID]!.creatorUserRecordID {
            localItem.owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
              withValue: creator.recordName,
              inContext: self.context)
            if let facebookID = recordsByID[recordID]!.valueForKey("OwnerFacebookID") as? String {
              localItem.owner!.facebookID = facebookID
            } else {
              print("OwnerFacebookID is not a String")
            }
            
          } else {
            print("creator is nil")
          }
          self.context.MR_saveToPersistentStoreAndWait()
        }
        
      }
      self.finishWithError(error)
    }
    database.addOperation(fetchAllItemsOperation)
  }
}