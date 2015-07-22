//
//  GetUploadsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord
/**
Retrieves the uploads of the specified person and stores them in the `uploads` property for that
`Person` object
*/
class GetUploadsOperation: Operation {
  let personIDName: String
  let database: CKDatabase
  let context: NSManagedObjectContext
  /**
  - parameter recordID: The user whose uploads need to be fetched
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data.
  */
  init(recordID: CKRecordID,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personIDName = recordID.recordName
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //create operation for fetching relevant records
    let getUploadsPredicate = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: personIDName))
    let getUploadsQuery = CKQuery(recordType: RecordTypes.Item, predicate: getUploadsPredicate)
    let getUploadsOperation = CKQueryOperation(query: getUploadsQuery)
    
    getUploadsOperation.recordFetchedBlock = { (record) -> Void in
        MagicalRecord.saveWithBlockAndWait { (context) -> Void in
        
        let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: record.recordID.recordName, inContext: context)
        
        localUpload.owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: self.personIDName, inContext: context)
        localUpload.recordIDName = record.recordID.recordName
        
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
        context.MR_saveToPersistentStoreAndWait()
      }
    }
    getUploadsOperation.queryCompletionBlock = { (cursor, error) -> Void in
      if error != nil { print("Get Uploads Finished With Error: \(error)") }
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getUploadsOperation)
  }
}