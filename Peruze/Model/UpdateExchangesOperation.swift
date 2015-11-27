//
//  UpdateExchangesOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class UpdateAllExchangesOperation: Operation {
  let database: CKDatabase
  let context: NSManagedObjectContext
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
    addObserver(NetworkObserver())
  }
  override func execute() {

    let allExchanges = Exchange.MR_findAll() as! [NSManagedObject]
    let allExchangesRecordIDNames = allExchanges.map { $0.valueForKey("recordIDName") as? String }
    
    var allExchangesRecordIDs = [CKRecordID]()
    for recordIDName in allExchangesRecordIDNames {
      if recordIDName != nil {
        allExchangesRecordIDs.append(CKRecordID(recordName: recordIDName!))
      }
    }
    
    
    let fetchUpdatedExchanges = CKFetchRecordsOperation(recordIDs: allExchangesRecordIDs)
    
    fetchUpdatedExchanges.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      guard let recordsByID = recordsByID else {
        print("Update Exchanges Operation recordsByID == nil")
        self.finish()
        return
      }
      self.cycleThroughDictionary(recordsByID)
      self.finish()
    }
    fetchUpdatedExchanges.qualityOfService = qualityOfService
    database.addOperation(fetchUpdatedExchanges)
  }
  
  private func cycleThroughDictionary(recordsByID: [NSObject: AnyObject]) {
    for key in recordsByID.keys {

      let recordID = key as! CKRecordID
      let record = recordsByID[recordID] as! CKRecord
      
      //find or create the record
      let localExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: recordID.recordName,
        inContext: self.context)

      //set creator
      if let creatorIDName = record.creatorUserRecordID?.recordName {
        let defaultOwnerName = "__defaultOwner__"
        if creatorIDName == defaultOwnerName {
          let me = Person.MR_findFirstOrCreateByAttribute("me", withValue: true, inContext: self.context)
          localExchange.setValue(me, forKey: "creator")
        } else {
          let creator = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: creatorIDName, inContext: self.context)
          localExchange.setValue(creator, forKey: "creator")
        }
      }

      //set exchange status
      if let newExchangeStatus = record.objectForKey("ExchangeStatus") as? Int {
        localExchange.setValue(NSNumber(integer: newExchangeStatus), forKey: "status")
      } else {
        print("Exchange Status was not set!!!")
      }

      //set date
      if let newDate = record.objectForKey("ExchangeDate") as? NSDate {
        localExchange.setValue(((localExchange.valueForKey("date") as? NSDate) ?? newDate), forKey: "date")
      }
  
      //set item offered
      if let itemOfferedReference = record.objectForKey("OfferedItem") as? CKReference {
        let itemOffered = Item.MR_findFirstOrCreateByAttribute("recordIDName", withValue: itemOfferedReference.recordID.recordName, inContext: self.context)
        localExchange.setValue(itemOffered, forKey: "itemOffered")
      }
      
      //set item requested
      if let itemRequestedReference = record.objectForKey("RequestedItem") as? CKReference {
        let itemRequested = Item.MR_findFirstOrCreateByAttribute("recordIDName", withValue: itemRequestedReference.recordID.recordName, inContext: self.context)
        localExchange.setValue(itemRequested, forKey: "itemRequested")
      }
      
      self.context.MR_saveToPersistentStoreAndWait()

    }
  }
  
}
/**
Overrides the value of the current
*/
class UpdateExchangeWithIncrementalData: Operation {
  let recordIDName: String
  let exchangeStatus: ExchangeStatus?
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(recordIDName: String,
    exchangeStatus: ExchangeStatus?,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.recordIDName = recordIDName
      self.exchangeStatus = exchangeStatus
      self.database = database
      self.context = context
      super.init()
  }
  override func execute() {
    let localExchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: recordIDName, inContext: context)
    let offeredItem = Item.MR_findFirstByAttribute("recordIDName", withValue: localExchange.itemOffered?.recordIDName, inContext: context)
    let requestedItem = Item.MR_findFirstByAttribute("recordIDName", withValue: localExchange.itemRequested?.recordIDName, inContext: context)
    offeredItem.hasRequested = "no"
    requestedItem.hasRequested = "no"
//    context.MR_saveToPersistentStoreAndWait()
    
    let exchangeRecordID = CKRecordID(recordName: recordIDName)
    let exchangeRecord = CKRecord(recordType: RecordTypes.Exchange, recordID: exchangeRecordID)
    
    if exchangeStatus != nil {
      localExchange.setValue(NSNumber(integer: exchangeStatus!.rawValue), forKey: "status")
      exchangeRecord.setObject(NSNumber(integer: exchangeStatus!.rawValue), forKey: "ExchangeStatus")
    }
    
    let cloudOp = CKModifyRecordsOperation(recordsToSave: [exchangeRecord], recordIDsToDelete: nil)
    cloudOp.savePolicy = CKRecordSavePolicy.ChangedKeys
    cloudOp.modifyRecordsCompletionBlock = { (savedRecords, _, error) -> Void in
      if let error = error {
        print("UpdateExchangeWithIncrementalData finished with error:")
        print(error)
        self.finishWithError(error)
      } else {
        self.context.MR_saveToPersistentStoreAndWait()
        self.finish()
      }
    }
    cloudOp.qualityOfService = qualityOfService
    database.addOperation(cloudOp)
  }
}
