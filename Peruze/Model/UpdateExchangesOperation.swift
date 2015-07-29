//
//  UpdateExchangesOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import MagicalRecord
import CloudKit

class UpdateAllExchangesOperation: Operation {
  let database: CKDatabase
  let context: NSManagedObjectContext
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  override func execute() {
    
    defer {
      context.MR_saveToPersistentStoreAndWait()
    }
    
    guard let allExchanges = Exchange.MR_findAll() as? [NSManagedObject] else {
      finish()
      return
    }
    
    let allExchangesRecordIDNames = allExchanges.map { $0.valueForKey("recordIDName") as? String }
    
    var allExchangesRecordIDs = [CKRecordID]()
    for recordIDName in allExchangesRecordIDNames where recordIDName != nil {
      allExchangesRecordIDs.append(CKRecordID(recordName: recordIDName!))
    }
    
    let fetchUpdatedExchanges = CKFetchRecordsOperation(recordIDs: allExchangesRecordIDs)
    fetchUpdatedExchanges.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      guard let recordsByID = recordsByID else {
        self.finishWithError(error)
        return
      }
      
      for recordID in recordsByID.keys {
        guard let record = recordsByID[recordID] else {
          self.finishWithError(error)
          return
        }
        
        //find or create the record
        let localExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: recordID.recordName,
          inContext: self.context)
        
        //set creator
        if let creatorIDName = record.creatorUserRecordID?.recordName {
          if creatorIDName == "__defaultOwner__" {
            localExchange.creator = Person.MR_findFirstOrCreateByAttribute("me",
              withValue: true,
              inContext: self.context)
          } else {
            localExchange.creator = Person.MR_findFirstOrCreateByAttribute("recordIDName",
              withValue: creatorIDName,
              inContext: self.context)
          }
        }
        
        
        //set exchange status
        if let newExchangeStatus = record.objectForKey("ExchangeStatus") as? Int {
          localExchange.status = NSNumber(integer: newExchangeStatus)//NSNumber(longLong: newExchangeStatus)
        } else {
          print("Exchange Status was not set!!!")
        }
        
        //set date
        if let newDate = record.objectForKey("ExchangeDate") as? NSDate {
          localExchange.date = localExchange.date ?? newDate
        }
        
        //set item offered
        if let itemOfferedReference = record.objectForKey("OfferedItem") as? CKReference {
          localExchange.itemOffered = Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: itemOfferedReference.recordID.recordName,
            inContext: self.context)
        }
        
        //set item requested
        if let itemRequestedReference = record.objectForKey("RequestedItem") as? CKReference {
          localExchange.itemRequested = Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: itemRequestedReference.recordID.recordName,
            inContext: self.context)
        }
        
        self.context.MR_saveToPersistentStoreAndWait()
      }
      self.finishWithError(error)
    }
    database.addOperation(fetchUpdatedExchanges)
  }
}
/**
Overrides the value of the current
*/
class UpdateExchangeWithIncrementalData: Operation {
  //TODO: Finish this
  init(context: NSManagedObjectContext) {
    super.init()
  }
  override func execute() {
    
  }
}
