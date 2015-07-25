//
//  GetReviewsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord
/**
Retrieves the reviews of the specified person and stores them in the `reviews` property for that
`Person` object
*/
class GetReviewsOperation: Operation {
  let personID: CKRecordID
  let database: CKDatabase
  let context: NSManagedObjectContext
  /**
  - parameter recordID: The user whose reviews need to be fetched
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data.
  */
  init(recordID: CKRecordID,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personID = recordID
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //create operation for fetching relevant records
    let personReference = CKReference(recordID: personID, action: .None)
    let getUploadsPredicate = NSPredicate(format: "UserBeingReviewed == %@", personReference)
    let getUploadsQuery = CKQuery(recordType: RecordTypes.Review, predicate: getUploadsPredicate)
    let getUploadsOperation = CKQueryOperation(query: getUploadsQuery)
    
    getUploadsOperation.recordFetchedBlock = { (record) -> Void in
      
        let localUpload = Item.findFirstOrCreateByAttribute("recordIDName",
          withValue: record.recordID.recordName, inContext: self.context)
        
        if let ownerRecordID = record.creatorUserRecordID?.recordName {
          localUpload.owner = Person.findFirstOrCreateByAttribute("recordIDName",
            withValue: ownerRecordID, inContext: self.context)
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
        self.context.MR_saveOnlySelfAndWait()
      
    }
    getUploadsOperation.queryCompletionBlock = { (cursor, error) -> Void in
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getUploadsOperation)
  }
}