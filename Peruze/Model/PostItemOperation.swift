//
//  PostItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class PostItemOperation: GroupOperation {
  private struct Constants {
    static let locationAccuracy: CLLocationAccuracy = 500 //meters
  }
  
  let operationQueue = OperationQueue()
  
  init(image: UIImage,
    title: String,
    detail: String,
    recordIDName: String? = nil,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    completionHandler: (Void -> Void) = { }) {
      
      //create the record if it doesn't exist
      let itemImageData = UIImagePNGRepresentation(image)
      let tempItem = Item.MR_findFirstOrCreateByAttribute("recordIDName", withValue: recordIDName, inContext: context)
      tempItem.setValue(itemImageData, forKey: "image")
      tempItem.setValue(title, forKey: "title")
      tempItem.setValue(detail, forKey: "detail")
      tempItem.setValue((recordIDName ?? "tempID"), forKey: "recordIDName")
      
      context.MR_saveToPersistentStoreAndWait()
      
      let item = Item.MR_findFirstByAttribute("recordIDName", withValue: recordIDName ?? "tempID", inContext: context)
      item.setValue(recordIDName, forKey: "recordIDName")
      
      /*
      This operation is made of four child operations:
      1. the operation to retrieve the user location
      2. the operation to save the item to the core data storage
      3. the operation to save the item to cloud kit key value storage
      4. finishing operation that calls the completion handler
      */
      
      let getLocationOp = LocationOperation(accuracy: Constants.locationAccuracy, manager: nil, handler: { (location: CLLocation) -> Void in
        
        //save latitude and longitude to item and self
        var error: NSError?
        let objectID = item.valueForKey("objectID") as! NSManagedObjectID
        let localItem = context.existingObjectWithID(objectID, error: &error)!
        if error != nil {
          print(error)
        } else {
          let localMe = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
          localItem.setValue(NSNumber(double: location.coordinate.longitude), forKey: "longitude")
          localItem.setValue(NSNumber(double: location.coordinate.latitude), forKey: "latitude")
          localMe.setValue(NSNumber(double: location.coordinate.longitude), forKey: "longitude")
          localMe.setValue(NSNumber(double: location.coordinate.latitude), forKey: "latitude")
          context.MR_saveToPersistentStoreAndWait()
        }
      })
      
      let saveItemOp = SaveItemInfoToLocalStorageOperation(
        title: title,
        detail: detail,
        image: itemImageData,
        objectID: item.objectID,
        context: context
      )
      let uploadItemOp = UploadItemFromLocalStorageToCloudOperation(objectID: item.objectID, database: database, context: context)
      let finishOp = NSBlockOperation(block: completionHandler)
      
      //add dependencies
      uploadItemOp.addDependencies([getLocationOp, saveItemOp])
      finishOp.addDependencies([getLocationOp, saveItemOp, uploadItemOp])
      
      //setup queue
      operationQueue.name = "Post Item Operation Queue"
      super.init(operations: [getLocationOp, saveItemOp, uploadItemOp, finishOp])
  }
}

/// Saves the given item to the local core data storage
class SaveItemInfoToLocalStorageOperation: Operation {
  
  let context: NSManagedObjectContext
  let objectID: NSManagedObjectID
  let title: String?
  let detail: String?
  let image: NSData?
  
  init(title: String?,
    detail: String?,
    image: NSData?,
    objectID: NSManagedObjectID,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.title = title
      self.detail = detail
      self.image = image
      self.context = context
      self.objectID = objectID
      super.init()
  }
  
  override func execute() {
    //Swift 2.0
    //do {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    //let localItem = try context.existingObjectWithID(self.objectID)
    var error: NSError?
    let localItem: NSManagedObject! = context.existingObjectWithID(self.objectID, error: &error)
    if error != nil { print(error) }
    
    localItem.objectID
    localItem.setValue(me, forKey: "owner")
    localItem.setValue(self.title, forKey: "title")
    localItem.setValue(self.detail, forKey: "detail")
    localItem.setValue(self.image, forKey: "image")
    localItem.setValue(me.valueForKey("facebookID"), forKey: "ownerFacebookID")
    //    } catch {
    //      print("Error in SaveItemInfoToLocalStorage: \(error)")
    //    }
    
    context.MR_saveToPersistentStoreAndWait()
    finish()
    
  }
}

/// Uploads the given item record ID from local storage to CloudKit
class UploadItemFromLocalStorageToCloudOperation: Operation {
  let database: CKDatabase
  let context: NSManagedObjectContext
  let objectID: NSManagedObjectID
  
  init(objectID: NSManagedObjectID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    self.objectID = objectID
    super.init()
    addObserver(NetworkObserver())
  }
  
  override func execute() {
    
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    var error: NSError?
    let itemToSave: NSManagedObject! = context.existingObjectWithID(objectID, error: &error)
    
    if error != nil {
      self.finish(GenericError.ExecutionFailed)
      return
    }
    
    
    //update server storage
    let recordIDName = itemToSave.valueForKey("recordIDName") as? String
    var itemRecord: CKRecord
    if recordIDName == nil {
      itemRecord = CKRecord(recordType: RecordTypes.Item)
    } else {
      itemRecord = CKRecord(recordType: RecordTypes.Item, recordID: CKRecordID(recordName: recordIDName!))
    }
    
    //set immediately available keys
    let itemTitle = itemToSave.valueForKey("title") as? String
    let itemDetail = itemToSave.valueForKey("detail") as? String
    
    itemRecord.setObject(itemTitle, forKey: "Title")
    itemRecord.setObject(itemDetail, forKey: "Description")
    itemRecord.setObject((me.valueForKey("facebookID") as? String), forKey: "OwnerFacebookID")
    
    //retrieve location
    if let itemLat = itemToSave.valueForKey("latitude") as? NSNumber,
      let itemLong = itemToSave.valueForKey("longitude") as? NSNumber {
        let itemLocation = CLLocation(latitude: itemLat.doubleValue, longitude: itemLong.doubleValue)
        itemRecord.setObject(itemLocation, forKey: "Location")
    }
    
    //get the imageURL
    ///URL for item image
    let imageURL = NSURL(fileURLWithPath: cachePathForFileName("tempFile"))
    let imageData = itemToSave.valueForKey("image") as? NSData
    if imageData!.writeToURL(imageURL!, atomically: true) {
      let imageAsset = CKAsset(fileURL: imageURL)
      itemRecord.setObject(imageAsset, forKey: "Image")
    } else {
      finish()
      return
    }
    
    let saveItemRecordOp = CKModifyRecordsOperation(recordsToSave: [itemRecord], recordIDsToDelete: nil)
    saveItemRecordOp.modifyRecordsCompletionBlock = { (savedRecords, _, error) -> Void in
      //print any returned errors
      if error != nil { print("UploadItem returned error: \(error)") }
      
      var deletionError: NSError?
      NSFileManager.defaultManager().removeItemAtPath(imageURL!.path!, error: &deletionError)
      if deletionError != nil {
        print(deletionError)
        return
      }
      
      if let first = savedRecords?.first as? CKRecord {
        itemToSave.setValue(first.recordID.recordName, forKey: "recordIDName")
      }
      
      self.context.MR_saveToPersistentStoreAndWait()
      self.finish(GenericError.ExecutionFailed)
    }
    saveItemRecordOp.qualityOfService = NSQualityOfService.Utility
    database.addOperation(saveItemRecordOp)
  }
  
  private func cachePathForFileName(name: String) -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
    let cachePath = paths.first as! String
    return cachePath.stringByAppendingPathComponent(name)
  }
  
}

