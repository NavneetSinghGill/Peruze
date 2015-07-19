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
  let personID: CKRecordID
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
    context: NSManagedObjectContext? = managedConcurrentObjectContext) {
    self.personID = recordID
    self.database = database
    self.context = context!
    super.init()
  }
  
  override func execute() {
    
    //create operation for fetching relevant records
    let getUploadsPredicate = NSPredicate(format: "creatorRecordID == %@", personID)
    let getUploadsQuery = CKQuery(recordType: RecordTypes.Item, predicate: getUploadsPredicate)
    let getUploadsOperation = CKQueryOperation(query: getUploadsQuery)
    
    getUploadsOperation.recordFetchedBlock = { (record) -> Void in
      MagicalRecord.saveWithBlockAndWait { (context) -> Void in
        
        let localUpload = Item.findFirstOrCreateByAttribute("recordIDName",
          withValue: record.recordID.recordName, inContext: context)
        
        if let ownerRecordID = record.creatorUserRecordID?.recordName {
          localUpload.owner = Person.findFirstOrCreateByAttribute("recordIDName",
            withValue: ownerRecordID, inContext: context)
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
        context.saveToPersistentStoreAndWait()
      }
    }
    getUploadsOperation.queryCompletionBlock = { (cursor, error) -> Void in
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getUploadsOperation)
  }
}