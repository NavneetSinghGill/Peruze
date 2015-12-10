//
//  File.swift
//  Peruze
//
//  Created by stplmacmini11 on 16/11/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

private let logging = true

class DeleteItemOperation: GroupOperation{
    private struct Constants {
    static let locationAccuracy: CLLocationAccuracy = 2000 //meters
  }
  
  let operationQueue = OperationQueue()
  let presentationContext: UIViewController
  let errorCompletionHandler: (Void -> Void)
  
  init(recordIDName: String? = nil,
    presentationContext: UIViewController,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    completionHandler: (Void -> Void) = { },
    errorCompletionHandler: (Void -> Void) = { }) {
      if logging { logw("DeleteItemOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
      
      let item = Item.MR_findFirstByAttribute("recordIDName", withValue: recordIDName, inContext: context)
      
      /*
      This operation is made of four child operations:
      1. the operation to delete the item from the cloud kit key value storage
      2. the operation to delete the item from core data storage
      3. finishing operation that calls the completion handler
      */
        
        
      let deleteFromCloudItemOp = DeleteItemFromLocalStorageToCloudOperation(
            objectID: item.objectID,
            database: database,
            context: context
      )
        
      let deleteFromLocalItemOp = DeleteItemFromLocalStorageOperation(
        objectID: item.objectID,
        context: context
      )
      
      let finishOp = BlockOperation(block: { (continueWithError) -> Void in
        completionHandler()
      })
      
      let presentNoLocOperation = AlertOperation(presentationContext: presentationContext)
      presentNoLocOperation.title = "No Location"
      presentNoLocOperation.message = "We were unable to access your location. We need your location to be able to show your item to the most relevant people! Please navigate to your Settings and allow location services for Peruze to upload an item."
      
      //add dependencies
      deleteFromLocalItemOp.addDependency(deleteFromCloudItemOp)
      finishOp.addDependency(deleteFromLocalItemOp)
      finishOp.addDependency(deleteFromCloudItemOp)
      
      var operationsToInit = [Operation]()
        operationsToInit = [deleteFromLocalItemOp, deleteFromCloudItemOp, finishOp]
      
      //setup local vars
      operationQueue.name = "Post Item Operation Queue"
      self.presentationContext = presentationContext
      self.errorCompletionHandler = errorCompletionHandler
      
      //initialize
      super.init(operations: operationsToInit)
      
      //add observers
      addObserver(NetworkObserver())
  }
  
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "Ouch :("
      alert.message = "There was a problem uploading your item to the server."
      produceOperation(alert)
      errorCompletionHandler()
    }
  }
  
}

/// Saves the given item to the local core data storage
class DeleteItemFromLocalStorageOperation: Operation {
  
  let context: NSManagedObjectContext
  let objectID: NSManagedObjectID
  
  init(objectID: NSManagedObjectID,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      if logging { logw("DeleteItemFromLocalStorageOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
      self.context = context
      self.objectID = objectID
      super.init()
  }
  
  override func execute() {
    if logging { logw("DeleteItemFromLocalStorageOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    
    do {
      let localItem = try context.existingObjectWithID(self.objectID)
        context.deleteObject(localItem)
    } catch {
      logw("\(error)")
    }
    
    logw("Deleting Item from Persistent Store and Waiting...")
    context.MR_saveToPersistentStoreAndWait()
    finish()
  }
  override func finished(errors: [NSError]) {
    if let firstError = errors.first {
      logw("DeleteItemFromLocalStorageOperation finished with an error: \(firstError)")
    } else {
      logw("DeleteItemFromLocalStorageOperation finished successfully")
    }
  }
}

/// Uploads the given item record ID from local storage to CloudKit
class DeleteItemFromLocalStorageToCloudOperation: Operation {
  let database: CKDatabase
  let context: NSManagedObjectContext
  let objectID: NSManagedObjectID
  
  init(objectID: NSManagedObjectID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    if logging { logw("DeleteItemFromLocalStorageToCloudOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    self.database = database
    self.context = context
    self.objectID = objectID
    super.init()
    addObserver(NetworkObserver())
  }
  
  override func execute() {
    if logging { logw("DeleteItemFromLocalStorageToCloudOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    
    do {
      let itemToDelete = try context.existingObjectWithID(objectID)
      
      //update server storage
      let recordIDName = itemToDelete.valueForKey("recordIDName") as? String
        
      let deleteItemRecordOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [CKRecordID(recordName: recordIDName!)])
      deleteItemRecordOp.modifyRecordsCompletionBlock = { (savedRecords, _, error) -> Void in
        //print any returned errors
        if error != nil { logw("UploadItem returned error: \(error)") }
        self.finish()
      }
        
      deleteItemRecordOp.qualityOfService = qualityOfService
      database.addOperation(deleteItemRecordOp)
    } catch {
      logw("\(error)")
      self.finish()
    }
  }
}
