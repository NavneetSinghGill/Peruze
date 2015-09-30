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
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personID = recordID
      self.database = database
      self.context = context
      super.init()
  }
  

  
  override func execute() {
    
    //create operation for fetching relevant records
    let personReference     = CKReference(recordID: personID, action: CKReferenceAction.None)
    let getReviewsPredicate = NSPredicate(format: "UserBeingReviewed == %@", personReference)
    let getReviewsQuery     = CKQuery(recordType: RecordTypes.Review, predicate: getReviewsPredicate)
    let getReviewsOperation = CKQueryOperation(query: getReviewsQuery)

    getReviewsOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in

      let localReview = Review.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      
      if let detail = record.objectForKey("Description") as? String {
        localReview.detail = detail
      }
      
      if let starRating = record.objectForKey("StarRating") as? NSNumber {
        localReview.starRating = starRating
      }
      
      if let title = record.objectForKey("Title") as? String {
        localReview.title = title
      }
      
      if let userBeingReviewed = record.objectForKey("UserBeingReviewed") as? CKReference {
        let userReviewedIDName = userBeingReviewed.recordID.recordName
        print(userReviewedIDName)
        let reviewedUser = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: userReviewedIDName, inContext: self.context)
        self.context.MR_saveToPersistentStoreAndWait()
        localReview.userBeingReviewed = reviewedUser
      }
      
      localReview.date = record.creationDate
      
      if let creator = record.creatorUserRecordID?.recordName {
        let reviewer = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: creator, inContext: self.context)
        self.context.MR_saveToPersistentStoreAndWait()
        localReview.reviewer = reviewer
      }

      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
    }
    getReviewsOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
      if error != nil {
        print("getReviewsOperation finished with error")
      }
      self.finish()
    }
    
    //add that operation to the operationQueue of self.database
    getReviewsOperation.qualityOfService = qualityOfService
    self.database.addOperation(getReviewsOperation)
  }
}