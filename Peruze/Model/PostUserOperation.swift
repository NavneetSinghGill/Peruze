//
//  PostUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/1/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

private let logging = true

private enum PostUserOperationError : ErrorType {
  case SaveImageFailed
  case DeleteImageFailedWithError(NSError!)
  case RecordNotSavedToServer
  case CloudKitOperaitonFailedWithError(NSError!)
  case FetchMyRecordFailedWithError(NSError!)
  case CastFailed
}

class PostUserOperation: Operation {
  let presentationContext: UIViewController
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(presentationContext: UIViewController, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.presentationContext = presentationContext
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    let firstName = myPerson.valueForKey("firstName") as! String
    let lastName = myPerson.valueForKey("lastName") as! String

    let facebookID = myPerson.valueForKey("facebookID") as! String
    
    //save the image to disk and create the asset for the image
    let imageURL = NSURL(fileURLWithPath: cachePathForFileName("tempFile"))
    
    if let imageData : NSData = myPerson.valueForKey("image") as? NSData {
        if !imageData.writeToURL(imageURL, atomically: true) {
            logw("imageData.writeToURL failed to write")
            self.finish()
            return
        }
    }
    
    let imageAsset = CKAsset(fileURL: imageURL)
    
    //create the record from the information
    //get my profile from the server
    
    let fetchMyRecord = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    fetchMyRecord.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      if let error = error {
        self.finishWithError(error)
        return
      }
      
      guard let myRecordID = recordsByID?.keys.first else {
        logw("myRecordID from fetchRecordsCompletionBlock in Post User Operation was nil")
        self.finish()
        return
      }
      guard let myRecord = recordsByID?[myRecordID] else {
        logw("myRecord from fetchRecordsCompletionBlock in Post User Operation was nil")
        self.finish()
        return
      }
      myRecord.setObject(firstName, forKey: "FirstName")
      myRecord.setObject(lastName, forKey: "LastName")
      myRecord.setObject(facebookID, forKey: "FacebookID")
      myRecord.setObject(imageAsset, forKey: "Image")
      
      let saveOp = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
      saveOp.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
        logw("saveOp.modifyRecordsCompletionBlock called.  ")
        
        if let error = operationError {
          self.finishWithError(error)
          return
        }
        
        
        do {
          try NSFileManager.defaultManager().removeItemAtURL(imageURL)
        } catch {
          logw("\(error)")
          self.finish()
          return
        }
        
        if savedRecords?.first == nil {
          logw("saved records in PostUserOperation was nil")
          self.finish()
          return
        }
        self.finish()
      }
      
      saveOp.qualityOfService = self.qualityOfService
      self.database.addOperation(saveOp)
    }
    self.database.addOperation(fetchMyRecord)
  }
  override func finished(errors: [NSError]) {
    if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    let alert = AlertOperation(presentationContext: presentationContext)
    alert.title = "Oh No!"
    
    if let firstError = errors.first as? PostUserOperationError {
      switch firstError {
      case .CloudKitOperaitonFailedWithError(let error) :
        alert.message = error.localizedDescription
        break
      case .DeleteImageFailedWithError(let error) :
        alert.message = "Failure Reason: " + (error.localizedFailureReason ?? "") +
          " Failure Description: " + error.localizedDescription +
          " Recovery Suggestion: " + (error.localizedRecoverySuggestion ?? "None")
        break
      case .RecordNotSavedToServer :
        alert.message = "Your user profile was not saved to our servers correctly. Sorry for the inconvenience!"
        break
      case .SaveImageFailed :
        alert.message = "There was a problem saving your profile picture to your phone's storage. You'll probably have to go through setup again later. Sorry for the inconvenience!"
        break
      case .CastFailed :
        alert.message = "The information returned from the server for your user was not correct. Please try again later."
        break
      case .FetchMyRecordFailedWithError(let error) :
        alert.message = error.localizedDescription
        break
      }
      produceOperation(alert)
    } else if errors.first != nil {
      alert.message = "There was a problem uploading your information to iCloud. You may have to go through profile setup again later. Sorry!"
      produceOperation(alert)
    }
  }
  
  private func cachePathForFileName(name: String) -> String {
    if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
    let cachePath = paths.first!
    let cacheURL : NSURL = (NSURL(string: cachePath)?.URLByAppendingPathComponent(name))!
    return (cacheURL.absoluteString)
  }
  
}

class UpdateUserOperation: Operation {
    let user: NSManagedObject!
    init(personToUpdate : NSManagedObject!) {
        user = personToUpdate
    }
    override func execute() {
        logw(__FUNCTION__ + " of " + __FILE__ + " called.  ")
        if let recordIDName = user.valueForKey("recordIDName") as? String {
            
            let firstName = user.valueForKey("firstName") as! String
            let lastName = user.valueForKey("lastName") as! String
            
            let facebookID = user.valueForKey("facebookID") as! String
            let isDelete = user.valueForKey("isDelete") as! String
            
            //save the image to disk and create the asset for the image
            let imageURL = NSURL(fileURLWithPath: cachePathForFileName("tempFile"))
            
            if let imageData : NSData = user.valueForKey("image") as? NSData {
                if !imageData.writeToURL(imageURL, atomically: true) {
                    logw("imageData.writeToURL failed to write")
                    self.finish()
                    return
                }
            }
            
            let imageAsset = CKAsset(fileURL: imageURL)
            let record = CKRecord(recordType: RecordTypes.User, recordID: CKRecordID(recordName: recordIDName))
            record.setObject(firstName, forKey: "FirstName")
            record.setObject(lastName, forKey: "LastName")
            record.setObject(facebookID, forKey: "FacebookID")
            record.setObject(isDelete, forKey: "IsDeleted")
            
            let updateUserOp = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            updateUserOp.modifyRecordsCompletionBlock = {
                (records, recordIDs, error) -> Void in
                if error == nil {
                    for record in records! {
                        let recordID = record.recordID.recordName
                        let person = Person.MR_findFirstByAttribute("recordIDName", withValue: recordID)
                        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                    }
                }
            }
            updateUserOp.savePolicy = .ChangedKeys
            updateUserOp.qualityOfService = qualityOfService
            CKContainer.defaultContainer().publicCloudDatabase.addOperation(updateUserOp)
        }
    }
    override func finished(errors: [NSError]) {
        logw("\(errors)")
    }
    
    private func cachePathForFileName(name: String) -> String {
        if logging { logw(__FUNCTION__ + " of " + __FILE__ + " called.  ") }
        
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        let cachePath = paths.first!
        let cacheURL : NSURL = (NSURL(string: cachePath)?.URLByAppendingPathComponent(name))!
        return (cacheURL.absoluteString)
    }
}

