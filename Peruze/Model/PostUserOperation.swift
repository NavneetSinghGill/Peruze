//
//  PostUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/1/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private let logging = true

class PostUserOperation: Operation {
  let presentationContext: UIViewController
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(presentationContext: UIViewController, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.presentationContext = presentationContext
    self.database = database
    self.context = context
    super.init()
    addCondition(CloudContainerCondition(container: CKContainer.defaultContainer()))
  }
  
  override func execute() {
    if logging { print("\n" + __FUNCTION__ + " of " + __FILE__ + " called. \n") }
    
    let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    let firstName = myPerson.valueForKey("firstName") as! String
    let lastName = myPerson.valueForKey("lastName") as! String
    let imageData = myPerson.valueForKey("image") as! NSData
    let facebookID = myPerson.valueForKey("facebookID") as! String
    let myRecordIDName = myPerson.valueForKey("recordIDName") as! String
    
    //save the image to disk and create the asset for the image
    let imageURL = NSURL(fileURLWithPath: cachePathForFileName("tempFile"))
    
    if !imageData.writeToURL(imageURL!, atomically: true) {
      self.finish(GenericError.ExecutionFailed)
      return
    }
    
    let imageAsset = CKAsset(fileURL: imageURL)
    
    //create the record from the information
    let myRecordID = CKRecordID(recordName: myRecordIDName)
    let myRecord = CKRecord(recordType: RecordTypes.User, recordID: myRecordID)
    
    myRecord.setObject(firstName, forKey: "FirstName")
    myRecord.setObject(lastName, forKey: "LastName")
    myRecord.setObject(facebookID, forKey: "FacebookID")
    myRecord.setObject(imageAsset, forKey: "Image")
    
    //create the operation
    let saveOp = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
    saveOp.savePolicy = CKRecordSavePolicy.ChangedKeys
    saveOp.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
      print("\n saveOp.modifyRecordsCompletionBlock called. \n")
      //Swift 2.0
      //      do {
      //        try NSFileManager.defaultManager().removeItemAtURL(imageURL)
      //      } catch {
      //        print(error)
      //      }
      
      //      guard let savedRecords = savedRecords where savedRecords.first != nil else {
      //        let error = NSError(code: OperationErrorCode.ExecutionFailed)
      //        self.finishWithError(error)
      //        return
      //      }
      
      var error: NSError?
      NSFileManager.defaultManager().removeItemAtURL(imageURL!, error: &error)
      if error != nil {
        print("\n")
        print(error)
        print("\n")
        self.finish(GenericError.ExecutionFailed)
      }
      
      if savedRecords.first == nil {
        self.finish(GenericError.ExecutionFailed)
        return
      }
      
      self.finish()
    }
    saveOp.qualityOfService = qualityOfService
    database.addOperation(saveOp)
  }
  override func finished(errors: [ErrorType]) {
    if logging { print("\n" + __FUNCTION__ + " of " + __FILE__ + " called. \n") }
    
    if errors.first != nil {
      let alert = AlertOperation(presentFromController: presentationContext)
      alert.title = "Upload User Information Error"
      alert.message = "There was a problem uploading your information to the iCloud server."
      produceOperation(alert)
    }
  }
  
  private func cachePathForFileName(name: String) -> String {
    if logging { print("\n" + __FUNCTION__ + " of " + __FILE__ + " called. \n") }
    
    let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
    let cachePath = paths.first! as! String
    return cachePath.stringByAppendingPathComponent(name)
  }
  
}

