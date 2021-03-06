//
//  PostExchangeOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/29/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog
/**
Saves an exchange with the given informaiton to the local server and then to the cloudkit
database. This also sets the creator of the exchange to the
*/
class PostExchangeOperation: GroupOperation {
  /*
  Posting an exchange consist of _ operations
  1. Create the exchange and save it to the local database
  2. Upload the exchange to the CloudKit database
  */
  var errorBlockk: (Void -> Void) = { }
  init(date: NSDate,
    status: ExchangeStatus,
    itemOfferedRecordIDName: String,
    itemRequestedRecordIDName: String,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    errorBlock: (Void -> Void) = { },
    completion: (Void -> Void) = { }) {
      self.errorBlockk = errorBlock
      //create the temporary ID
      let tempId = NSUUID().UUIDString
      
      //save exchange to the local database
      let saveOp = SaveExchangeToLocalStorageOperation(
        temporaryID: tempId,
        date: date,
        status: status,
        itemOfferedRecordIDName: itemOfferedRecordIDName,
        itemRequestedRecordIDName: itemRequestedRecordIDName,
        errorBlock: self.errorBlockk,
        database: database,
        context: context
      )
      
      //upload exchange to the server
      let uploadOp = UploadExchangeFromLocalStorageToCloudOperation(
        temporaryID: tempId,
        errorBlock: self.errorBlockk,
        database: database,
        context: context
      )
      
      //create operation for the completion block
      let finishOp = NSBlockOperation(block: completion)
      
      //add dependencies
      uploadOp.addDependency(saveOp)
      finishOp.addDependencies([saveOp, uploadOp])
      
      //init with operations
      super.init(operations: [saveOp, uploadOp, finishOp])
  }
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if errors.first != nil {
      logw("PostExchangeOperation finished with the following first error: ")
        logw("\(errors.first!)")
        self.errorBlockk()
    }
  }
}

class SaveExchangeToLocalStorageOperation: Operation {
  
  let temporaryID: String
  let date: NSDate
  let status: ExchangeStatus
  let itemOfferedRecordIDName: String
  let itemRequestedRecordIDName: String
    var errorBlockk: (Void -> Void) = { }
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(temporaryID: String,
    date: NSDate,
    status: ExchangeStatus,
    itemOfferedRecordIDName: String,
    itemRequestedRecordIDName: String,
    errorBlock: (Void -> Void) = { },
    database: CKDatabase,
    context: NSManagedObjectContext) {
      self.temporaryID = temporaryID
      self.date = date
      self.status = status
      self.itemOfferedRecordIDName = itemOfferedRecordIDName
      self.itemRequestedRecordIDName = itemRequestedRecordIDName
        self.errorBlockk = errorBlock
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    let localExchange = Exchange.MR_createEntityInContext(context)
    localExchange.setValue(temporaryID, forKey: "recordIDName")
    localExchange.setValue(date, forKey: "date")
    localExchange.setValue(NSNumber(integer: status.rawValue), forKey: "status")
    
    let itemOffered = Item.MR_findFirstOrCreateByAttribute(
      "recordIDName",
      withValue: itemOfferedRecordIDName,
      inContext: context)
    localExchange.setValue(itemOffered, forKey: "itemOffered")
    
    let itemRequested = Item.MR_findFirstOrCreateByAttribute(
      "recordIDName",
      withValue: itemRequestedRecordIDName,
      inContext: context)
    itemRequested.setValue("yes", forKey: "hasRequested")
    localExchange.setValue(itemRequested, forKey: "itemRequested")
    
    let creator = Person.MR_findFirstByAttribute(
      "me",
      withValue: true,
      inContext: context)
    localExchange.setValue(creator, forKey: "creator")
    
    context.MR_saveToPersistentStoreAndWait()
    NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruseItemMainScreen", object: nil)
    finish()
  }
  
}

class UploadExchangeFromLocalStorageToCloudOperation: Operation {
  
  let temporaryID: String
    var errorBlockk: (Void -> Void) = { }
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(temporaryID: String,
    errorBlock: (Void -> Void) = { },
    database: CKDatabase,
    context: NSManagedObjectContext) {
      self.temporaryID = temporaryID
        self.errorBlockk = errorBlock
      self.database = database
      self.context = context
      super.init()
      addObserver(NetworkObserver())
  }
  
  override func execute() {
    let localExchange = Exchange.MR_findFirstByAttribute(
      "recordIDName",
      withValue: temporaryID,
      inContext: context)
    
    //create the record
    let exchangeRecord = CKRecord(recordType: RecordTypes.Exchange)
    
    //set DateExchanged
    if let exchangeDate = localExchange.valueForKey("date") as? NSDate {
      exchangeRecord.setObject(exchangeDate, forKey: "DateExchanged")
    }
    
    //set ExchangeStatus
    if let status = localExchange.valueForKey("status") as? NSNumber {
      exchangeRecord.setObject(status, forKey: "ExchangeStatus")
    }
    
    //set OfferedItem
    if let offeredItem = localExchange.valueForKey("itemOffered") as? NSManagedObject {
      if let offeredItemID = offeredItem.valueForKey("recordIDName") as? String {
        let offeredID = CKRecordID(recordName: offeredItemID)
        let offeredRef = CKReference(recordID: offeredID, action: CKReferenceAction.None)
        exchangeRecord.setObject(offeredRef, forKey: "OfferedItem")
        
        //set OfferedItemOwnerRecordIDName
        if
            let offeredItemOwner = offeredItem.valueForKey("owner") as? NSManagedObject,
            let ownerRecordIDName = offeredItemOwner.valueForKey("recordIDName") as? String {
                exchangeRecord.setObject(ownerRecordIDName, forKey: "OfferedItemOwnerRecordIDName")
        }
      }
    }
    
    //set RequestedItem
    if
      let requestedItem = localExchange.valueForKey("itemRequested") as? NSManagedObject,
      let requestedItemID = requestedItem.valueForKey("recordIDName") as? String {
        
        let requestedID = CKRecordID(recordName: requestedItemID)
        let requestedRef = CKReference(recordID: requestedID, action: CKReferenceAction.None)
        exchangeRecord.setObject(requestedRef, forKey: "RequestedItem")
        
        //set RequestedItemOwnerRecordIDName
        if
          let requestedItemOwner = requestedItem.valueForKey("owner") as? NSManagedObject,
          let ownerRecordIDName = requestedItemOwner.valueForKey("recordIDName") as? String {
            exchangeRecord.setObject(ownerRecordIDName, forKey: "RequestedItemOwnerRecordIDName")
        }
    }
    
    let uploadOp = CKModifyRecordsOperation(recordsToSave: [exchangeRecord], recordIDsToDelete: nil)
    uploadOp.modifyRecordsCompletionBlock = { (savedRecords, _, error) -> Void in
      
        if savedRecords!.count > 0 {
            let uploadedRecord = savedRecords!.first!
            
            localExchange.setValue(uploadedRecord.recordID.recordName, forKey: "recordIDName")
            
            self.context.MR_saveToPersistentStoreAndWait()
            self.finishWithError(error)
        }
        if error != nil {
            let exchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: self.temporaryID, inContext: self.context)
            exchange.valueForKey("itemOffered")!.setValue("no", forKey: "hasRequested")
            exchange.valueForKey("itemRequested")!.setValue("no", forKey: "hasRequested")
            self.context.deleteObject(exchange)
            self.context.MR_saveToPersistentStoreAndWait()
            self.errorBlockk()
        }
    }
    uploadOp.qualityOfService = qualityOfService
    database.addOperation(uploadOp)
  }
  
}