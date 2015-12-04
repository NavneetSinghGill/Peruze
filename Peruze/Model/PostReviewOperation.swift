//
//  PostReviewOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/25/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class PostReviewOperation: GroupOperation {
  
    let presentationContext: UIViewController
    let context: NSManagedObjectContext
    let database: CKDatabase
    let starRating: Int
    let title: String
    let review: String
    let userBeingReviewRecordIDName: String
  
  init(title: String,
    review: String,
    starRating: Int,
    userBeingReviewRecordIDName: String,
    presentationContext: UIViewController,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
    completion: (Void -> Void)) {
        self.presentationContext = presentationContext
        self.context = context
        self.database = database
        self.starRating = starRating
        self.title = title
        self.review = review
        self.userBeingReviewRecordIDName = userBeingReviewRecordIDName
        
        let tempID = NSUUID().UUIDString
        
        let saveToLocalOp = SaveReviewWithTempRecordIDOperation(
            rating: starRating,
            title: title,
            review: review,
            userBeingReviewRecordIDName: userBeingReviewRecordIDName,
            tempID: tempID,
            context: context,
            database: database)
        
        let uploadReviewOp = UploadReviewWithTempRecordIDOperation(
            temporaryID: tempID,
            database: database,
            context: context)
        
        let finishOp = NSBlockOperation(block: completion)
        uploadReviewOp.addDependency(saveToLocalOp)
        finishOp.addDependency(saveToLocalOp)
        finishOp.addDependency(uploadReviewOp)
        super.init(operations: [saveToLocalOp, uploadReviewOp, finishOp])
        
  }
  
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.message = ""
      alert.title = ""
    }
  }
  
}

class SaveReviewWithTempRecordIDOperation: Operation {
    let starRating: Int
    let title: String
    let review: String
    let userBeingReviewRecordIDName: String
    let tempID: String
    let context: NSManagedObjectContext
    let database: CKDatabase
    
    init(rating: Int,
        title: String,
        review: String,
        userBeingReviewRecordIDName: String,
        tempID: String,
        context: NSManagedObjectContext,
        database: CKDatabase) {
        self.starRating = rating
        self.title = title
        self.review = review
        self.userBeingReviewRecordIDName = userBeingReviewRecordIDName
        self.tempID = tempID
        self.context = context
        self.database = database
    }
    override func execute() {
        let newReview = Review.MR_createEntityInContext(context)
        newReview.setValue(starRating, forKey: "starRating")
        newReview.setValue(title, forKey: "title")
        newReview.setValue(review, forKey: "detail")
        newReview.setValue(tempID, forKey: "recordIDName")
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
        newReview.setValue(me, forKey: "reviewer")
        let userBeingReviewed = Person.MR_findFirstByAttribute("recordIDName", withValue: self.userBeingReviewRecordIDName, inContext: context)
        newReview.setValue(userBeingReviewed, forKey: "userBeingReviewed")
        context.MR_saveToPersistentStoreAndWait()
        finish()
    }
}

class UploadReviewWithTempRecordIDOperation: Operation {
    let temporaryID: String
    let database: CKDatabase
    let context: NSManagedObjectContext
    
    init(temporaryID: String,
        database: CKDatabase,
        context: NSManagedObjectContext = managedConcurrentObjectContext) {
            self.temporaryID = temporaryID
            self.database = database
            self.context = context
            super.init()
            addObserver(NetworkObserver())
    }
    
    override func execute() {
        let localReview = Review.MR_findFirstByAttribute("recordIDName", withValue: temporaryID, inContext: context)
        
        let reviewRecord = CKRecord(recordType: RecordTypes.Review)
        reviewRecord.setObject(localReview.valueForKey("starRating") as? Int, forKey: "StarRating")
        reviewRecord.setObject(localReview.valueForKey("title") as? String, forKey: "Title")
        reviewRecord.setObject(localReview.valueForKey("detail") as? String, forKey: "Description")
        
        if let userBeingReviewed = localReview.valueForKey("userBeingReviewed") as? NSManagedObject,
            let userBeingReviewedID = userBeingReviewed.valueForKey("recordIDName") as? String {
                let userBeingReviewedRecordIDName = CKRecordID(recordName: userBeingReviewedID)
                let userBeingReviewedRef = CKReference(recordID: userBeingReviewedRecordIDName, action: .None)
                reviewRecord.setObject(userBeingReviewedRef, forKey: "UserBeingReviewed")
        }
        
        let saveRecordsOp = CKModifyRecordsOperation(recordsToSave: [reviewRecord], recordIDsToDelete: nil)
        
        saveRecordsOp.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
            localReview.setValue(savedRecords?.first?.recordID.recordName, forKey: "recordIDName")
            localReview.setValue(savedRecords?.first?.valueForKey("modificationDate"), forKey: "date")
            self.context.MR_saveToPersistentStoreAndWait()
            self.finishWithError(operationError)
        }
        saveRecordsOp.qualityOfService = qualityOfService
        database.addOperation(saveRecordsOp)
    }
}