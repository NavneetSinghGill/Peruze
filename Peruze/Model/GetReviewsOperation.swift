//
//  GetReviewsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

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
    
    //create operation for fetching relevant records
    let personReference     = CKReference(recordID: personID, action: CKReferenceAction.None)
    let getUploadsPredicate = NSPredicate(format: "UserBeingReviewed == %@", personReference)
    let getUploadsQuery     = CKQuery(recordType: RecordTypes.Review, predicate: getUploadsPredicate)
    let getUploadsOperation = CKQueryOperation(query: getUploadsQuery)

    getUploadsOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in

      let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      
      let creator = record.creatorUserRecordID.recordName
      
      if creator != nil {
        let defaultCreatorString: String! = "__defaultOwner__"
        if creator == defaultCreatorString {
          let localOwner = Person.MR_findFirstOrCreateByAttribute("me", withValue: true, inContext: self.context)
          localUpload.setValue(localOwner, forKey: "owner")
        } else {
          let localOwner = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: record.creatorUserRecordID.recordName, inContext: self.context)
          localUpload.setValue(localOwner, forKey: "owner")
        }
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
        localUpload.setValue(NSData(contentsOfURL: imageAsset.fileURL), forKey: "image")
      }

      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
    }
    getUploadsOperation.queryCompletionBlock = { (cursor: CKQueryCursor!, error: NSError!) -> Void in
      self.finish(GenericError.ExecutionFailed)
    }
    
    //add that operation to the operationQueue of self.database
    getUploadsOperation.qualityOfService = qualityOfService
    self.database.addOperation(getUploadsOperation)
  }
}