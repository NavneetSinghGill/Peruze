//
//  PostMessageOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/26/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

class PostMessageOperation: GroupOperation {
  
  init(date: NSDate,
    text: String?,
    image: UIImage?,
    exchangeRecordIDName: String,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    completion: (Void -> Void) = {}) {
      
      /*
      This operation is made up of _ sub operations
      1. Save the message to the local database
      2. Upload the message to the cloud
      */
      let tempID = NSUUID().UUIDString
      
      let saveOp = SaveMessageWithTempRecordIDOperation(
        tempID: tempID,
        text: text,
        image: image,
        exchangeRecordIDName: exchangeRecordIDName,
        date: date,
        database: database,
        context: context
      )
      
      let uploadOp = UploadMessageWithTempRecordIDOperation(
        temporaryID: tempID,
        exchangeRecordIDName: exchangeRecordIDName,
        database: database,
        context: context
      )
      
      let finishOp = NSBlockOperation(block: completion)
      uploadOp.addDependency(saveOp)
      finishOp.addDependencies([saveOp, uploadOp])
      super.init(operations: [uploadOp, saveOp, finishOp])
  }
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if errors.count != 0 {
      logw("PostMessageOperation finished with errors:")
      logw("\(errors)")
    }
  }
}

/**
Saves the message with the given temporary ID to the local database.
*/
class SaveMessageWithTempRecordIDOperation: Operation {
  let tempID: String
  let text: String?
  let image: UIImage?
  let date: NSDate
  let database: CKDatabase
  let context: NSManagedObjectContext
  let exchangeRecordIDName: String
  
  init(tempID: String,
    text: String?,
    image: UIImage?,
    exchangeRecordIDName: String,
    date: NSDate,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.tempID = tempID
      self.text = text
      self.image = image
      self.exchangeRecordIDName = exchangeRecordIDName
      self.date = date
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    let newMessage = Message.MR_createEntityInContext(managedConcurrentObjectContext)
    let exchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: exchangeRecordIDName, inContext: context)
    newMessage.setValue(date, forKey: "date")
    newMessage.setValue(text, forKey: "text")
    newMessage.setValue(me, forKey: "sender")
    newMessage.setValue(tempID, forKey: "recordIDName")
    newMessage.setValue(exchange, forKey: "exchange")
    newMessage.setValue(me.valueForKey("recordIDName") as! String, forKey: "senderRecordIDName")
    if exchange.itemOffered?.owner?.recordIDName != me.recordIDName {
        newMessage.setValue(exchange.itemOffered?.owner?.recordIDName, forKey: "receiverRecordIDName")
    } else {
        newMessage.setValue(exchange.itemRequested?.owner?.recordIDName, forKey: "receiverRecordIDName")
    }
    
    if self.image != nil {
        let uniqueImageName = createUniqueName()
        let uploadRequest = Model.sharedInstance().uploadRequestForImageWithKey(uniqueImageName, andImage: self.image!)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {task in
            if task.error != nil {
                logw("PostMessageOperation Image upload to s3 failed with error: \(task.error)")
            } else {
                logw("PostMessageOperation Image upload to s3 success")
                newMessage.setValue(uniqueImageName, forKey: "imageUrl")
                self.context.MR_saveToPersistentStoreAndWait()
                self.finish()
            }
            return nil
        })
    } else {
        self.context.MR_saveToPersistentStoreAndWait()
        self.finish()
    }
  }
}

/**
Uploads the message with the given temporary ID to the cloud server and then replaces the
temporary ID from the message with the actual ID from the server.
*/
class UploadMessageWithTempRecordIDOperation: Operation {
  let temporaryID: String
  let exchangeRecordIDName: String
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(temporaryID: String,
    exchangeRecordIDName: String,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.temporaryID = temporaryID
      self.exchangeRecordIDName = exchangeRecordIDName
      self.database = database
      self.context = context
      super.init()
      addObserver(NetworkObserver())
  }
  
  override func execute() {
    let localMessage = Message.MR_findFirstByAttribute("recordIDName", withValue: temporaryID, inContext: context)
    
    let messageRecord = CKRecord(recordType: RecordTypes.Message)
    messageRecord.setObject(localMessage.valueForKey("text") as? String, forKey: "Text")
//    messageRecord.setObject(localMessage.valueForKey("image") as? NSData, forKey: "Image")
    messageRecord.setObject(localMessage.valueForKey("date") as? NSDate, forKey: "Date")
    messageRecord.setObject(localMessage.valueForKey("senderRecordIDName") as? String, forKey: "SenderRecordIDName")
    messageRecord.setObject(localMessage.valueForKey("receiverRecordIDName") as? String, forKey: "ReceiverRecordIDName")
    if let exchange = localMessage.valueForKey("Exchange") as? NSManagedObject,
      let exchangeID = exchange.valueForKey("recordIDName") as? String {
        let exchangeRecordID = CKRecordID(recordName: exchangeID)
        let exchangeRef = CKReference(recordID: exchangeRecordID, action: .None)
        messageRecord.setObject(exchangeRef, forKey: "Exchange")
    }
    messageRecord.setObject(localMessage.valueForKey("imageUrl") as? String, forKey: "ImageUrl")
    
    let saveRecordsOp = CKModifyRecordsOperation(recordsToSave: [messageRecord], recordIDsToDelete: nil)
    
    saveRecordsOp.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
      localMessage.setValue(savedRecords?.first?.recordID.recordName, forKey: "recordIDName")
        let localExchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: self.exchangeRecordIDName,inContext: self.context)
        localExchange.setValue(savedRecords?.first?.modificationDate!, forKey: "dateOfLatestChat")
        
      self.context.MR_saveToPersistentStoreAndWait()
      self.finishWithError(operationError)
    }
    saveRecordsOp.qualityOfService = qualityOfService
    database.addOperation(saveRecordsOp)
  }
}