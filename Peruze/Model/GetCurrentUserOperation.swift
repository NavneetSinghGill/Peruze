//
//  GetCurrentUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/20/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

private enum CurrentUserOperationError: ErrorType {
  case CloudKitError(NSError)
}

class GetCurrentUserOperation: Operation {
  
  private let context: NSManagedObjectContext
  private let database: CKDatabase
  private let presentationContext: UIViewController
  internal var finishedBlock : (error :NSError) -> (Void)
  
  init(presentationContext: UIViewController, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    
    self.presentationContext = presentationContext
    self.database = database
    self.context = context
    self.finishedBlock = { error in }
    super.init()
    
    addObserver(NetworkObserver())
  }
  
  override func execute() {
    
    logw("\n\n \(NSDate())\nExecute of Get Current User from iCloud Operation\n\n")
    let fetchUser = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    fetchUser.perRecordCompletionBlock = { (record, recordID, error) -> Void in
      logw("\n\n \(NSDate()) Fetched Current User from iCloud Operation \n \(record)")
      //make sure there were no errors
      if let error = error {
        logw("GetCurrentUserOperation failed with error:")
        logw("\(error)")
        self.finishWithError(error)
        return
      }
      
      guard let record = record else {
        logw("The record returned from the server was nil")
        return
      }
      
      //save the records to the local DB
      var person = Person.MR_findFirstOrCreateByAttribute("me",
        withValue: true,
        inContext: self.context)
      
      
      //set the returned properties
      let firstName  = (record.objectForKey("FirstName")  as? String)
      let lastName   = (record.objectForKey("LastName")   as? String)
      let facebookID = (record.objectForKey("FacebookID") as? String)
      let isDelete = (record.objectForKey("IsDeleted") as? Int)
      let imageUrl = (record.objectForKey("ImageUrl") as? String)
        
        // if firstName == nil it means it's the very first time any user is logging to device
        if (person?.valueForKey("FacebookID") as? String) != facebookID && firstName != nil{
            person.facebookID = nil
            person.firstName = nil
            person.lastName = nil
            person.image = nil
            self.context.MR_saveToPersistentStoreAndWait()
            let error = NSError(domain: "Error: New user", code: 123, userInfo: ["isNewUser":"yes", "firstName":firstName!])
            self.finishedBlock(error: error)
            self.cancel()
        }
        
//        person.setValue(false, forKey: "me")
//        
//      person = Person.MR_findFirstOrCreateByAttribute("facebookID", withValue: record.objectForKey("FacebookID"), inContext: self.context)
      person.setValue(recordID!.recordName, forKey: "recordIDName")
      person.setValue(firstName, forKey: "firstName")
      person.setValue(lastName, forKey: "lastName")
      person.setValue(facebookID, forKey: "facebookID")
//        person.setValue(true, forKey: "me")
        if isDelete == nil {
           person.setValue(0, forKey: "isDelete")
        }
      person.setValue(imageUrl, forKey: "imageUrl")
      
      //check for image property and set the data
//      if let imageAsset = record.objectForKey("Image") as? CKAsset {
//        let imageData = NSData(contentsOfURL: imageAsset.fileURL)
//        person.setValue(imageData, forKey: "image")
//      }
      
//        if imageUrl != nil {
//            let downloadingFilePath = NSTemporaryDirectory()
//            let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrl!, downloadingFilePath: downloadingFilePath)
//            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//            let task = transferManager.download(downloadRequest)
//            task.continueWithBlock({ (task) -> AnyObject? in
//                if task.error != nil {
//                    logw("GetItemOperation image download failed with error: \(task.error!)")
//                } else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        let fileUrl = task.result!.valueForKey("body")!
//                        let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                        person.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                    }
//                }
//                return nil
//            })
//        }
        
      //check for favorites
      if let favoriteReferences = record.objectForKey("FavoriteItems") as? [CKReference] {
        let favorites = favoriteReferences.map {
          Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: $0.recordID.recordName , inContext: self.context)
        }
        let favoritesSet = NSSet(array: favorites)
        person.setValue(favoritesSet, forKey: "favorites")
      }
      
        //save the context
        self.context.MR_saveToPersistentStoreAndWait()
        self.finish()
    
        
    }
    
    //add operation to the cloud kit database
    fetchUser.qualityOfService = qualityOfService
    database.addOperation(fetchUser)
  }
  override func finished(errors: [NSError]) {
    
    let alert = AlertOperation(presentationContext: presentationContext)
    alert.title = "iCloud Error"
    
    
    if let firstError = errors.first {
        let errorCode : CKErrorCode = CKErrorCode(rawValue: firstError.code)!
      switch errorCode {
      case .NotAuthenticated :
        alert.message = "There was an error getting your user from iCloud. Make sure you're logged into iCloud in Settings and iCloud Drive is turned on for Peruze."
        break
      default:
        alert.message = "Getting your information with the server failed with the following error: " + firstError.localizedDescription
        break
      }
        alert.addCompletionBlock({Void in
            self.finishedBlock(error: firstError)
        })
        produceOperation(alert)
    }
//    else {
//      alert.message = "There was an error getting your user from iCloud. Make sure you're logged into iCloud in Settings and iCloud Drive is turned on for Peruze."
//    }
    
  }
}