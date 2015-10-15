//
//  PostItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private let logging = true

class PostItemOperation: GroupOperation {
  private struct Constants {
    static let locationAccuracy: CLLocationAccuracy = 2000 //meters
  }
  
  let operationQueue = OperationQueue()
  let presentationContext: UIViewController
  let errorCompletionHandler: (Void -> Void)
  
  init(image: UIImage,
    title: String,
    detail: String,
    recordIDName: String? = nil,
    presentationContext: UIViewController,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    completionHandler: (Void -> Void) = { },
    errorCompletionHandler: (Void -> Void) = { }) {
      if logging { print("PostItemOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
      
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
      
      //ask the user for location permissio
      let locCondition = LocationCondition(usage: LocationCondition.Usage.WhenInUse)
      let getLocationOp = LocationOperation(accuracy: Constants.locationAccuracy) { (location) -> Void in
        print("getLocationOp handler - - - - - - -  ")
        //save latitude and longitude to item and self
        let objectID = item.valueForKey("objectID") as! NSManagedObjectID
        do {
          let localItem = try context.existingObjectWithID(objectID)
          let localMe = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
          localItem.setValue(NSNumber(double: location.coordinate.longitude), forKey: "longitude")
          localItem.setValue(NSNumber(double: location.coordinate.latitude), forKey: "latitude")
          localMe.setValue(NSNumber(double: location.coordinate.longitude), forKey: "longitude")
          localMe.setValue(NSNumber(double: location.coordinate.latitude), forKey: "latitude")
          context.MR_saveToPersistentStoreAndWait()
        } catch {
          print(error)
        }
      }
      
      let saveItemOp = SaveItemInfoToLocalStorageOperation(
        title: title,
        detail: detail,
        image: itemImageData,
        objectID: item.objectID,
        context: context
      )
      
      let uploadItemOp = UploadItemFromLocalStorageToCloudOperation(
        objectID: item.objectID,
        database: database,
        context: context
      )
      
      let finishOp = BlockOperation(block: { (continueWithError) -> Void in
        completionHandler()
      })
      
      let presentNoLocOperation = AlertOperation(presentationContext: presentationContext)
      presentNoLocOperation.title = "No Location"
      presentNoLocOperation.message = "We were unable to access your location. We need your location to be able to show your item to the most relevant people! Please navigate to your Settings and allow location services for Peruze to upload an item."
      
      //add dependencies
      uploadItemOp.addDependency(getLocationOp)
      uploadItemOp.addDependency(saveItemOp)
      finishOp.addDependency(getLocationOp)
      finishOp.addDependency(saveItemOp)
      finishOp.addDependency(uploadItemOp)
      
      var operationsToInit = [Operation]()
      locCondition.evaluateForOperation(getLocationOp) { (result: OperationConditionResult) -> Void in
        switch result {
        case .Satisfied :
          operationsToInit = [ getLocationOp, saveItemOp, uploadItemOp, finishOp]
          break
        case .Failed(let error) :
          print(error)
          let finishWithErrorOp = BlockOperation(block: { (continueWithError) -> Void in
            errorCompletionHandler()
          })
          operationsToInit = [presentNoLocOperation, finishWithErrorOp]
        }
      }
      
      //setup local vars
      operationQueue.name = "Post Item Operation Queue"
      self.presentationContext = presentationContext
      self.errorCompletionHandler = errorCompletionHandler
      
      //initialize
      super.init(operations: operationsToInit)
      
      //add observers
      addObserver(NetworkObserver())
  }
  
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "Ouch :("
      alert.message = "There was a problem uploading your item to the server."
      produceOperation(alert)
      errorCompletionHandler()
    }
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
      if logging { print("SaveItemInfoToLocalStorageOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
      self.title = title
      self.detail = detail
      self.image = image
      self.context = context
      self.objectID = objectID
      super.init()
  }
  
  override func execute() {
    if logging { print("SaveItemInfoToLocalStorageOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    do {
      let localItem = try context.existingObjectWithID(self.objectID)
      localItem.objectID
      localItem.setValue(me, forKey: "owner")
      localItem.setValue(self.title, forKey: "title")
      localItem.setValue(self.detail, forKey: "detail")
      localItem.setValue(self.image, forKey: "image")
      localItem.setValue(me.valueForKey("facebookID"), forKey: "ownerFacebookID")
      
    } catch {
      print(error)
    }
    
    print("Saving Item to Persistent Store and Waiting...")
    context.MR_saveToPersistentStoreAndWait()
    finish()
  }
  override func finished(errors: [NSError]) {
    if let firstError = errors.first {
      print("SaveItemInfoToLocalStorageOperation finished with an error: \(firstError)")
    } else {
      print("SaveItemInfoToLocalStorageOperation finished successfully")
    }
  }
}

/// Uploads the given item record ID from local storage to CloudKit
class UploadItemFromLocalStorageToCloudOperation: Operation {
  let database: CKDatabase
  let context: NSManagedObjectContext
  let objectID: NSManagedObjectID
  
  init(objectID: NSManagedObjectID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    if logging { print("UploadItemFromLocalStorageToCloudOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    self.database = database
    self.context = context
    self.objectID = objectID
    super.init()
    addObserver(NetworkObserver())
  }
  
  override func execute() {
    if logging { print("UploadItemFromLocalStorageToCloudOperation " + __FUNCTION__ + " in " + __FILE__ + ". ") }
    
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    
    do {
      let itemToSave = try context.existingObjectWithID(objectID)
      
      //update server storage
      let recordIDName = itemToSave.valueForKey("recordIDName") as? String
      var itemRecord: CKRecord
      if let recordIDName = itemToSave.valueForKey("recordIDName") as? String {
        itemRecord = CKRecord(recordType: RecordTypes.Item, recordID: CKRecordID(recordName: recordIDName))
      } else {
        itemRecord = CKRecord(recordType: RecordTypes.Item)
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
      if imageData!.writeToURL(imageURL, atomically: true) {
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
        
        do {
          try NSFileManager.defaultManager().removeItemAtPath(imageURL.path!)
        } catch {
          print(error)
          return
        }
        
        if let first = savedRecords?.first {
          itemToSave.setValue(first.recordID.recordName, forKey: "recordIDName")
        }
        
        self.context.MR_saveToPersistentStoreAndWait()
        self.finish()
      }
      saveItemRecordOp.qualityOfService = qualityOfService
      database.addOperation(saveItemRecordOp)
    } catch {
      print(error)
      self.finish()
    }
  }
  
  private func cachePathForFileName(name: String) -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
    let cachePath = NSURL(string: paths.first!)!.URLByAppendingPathComponent(name)
    return cachePath.path!
  }
  
}

