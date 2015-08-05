//
//  PostFavoriteOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/31/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord


class PostFavoriteOperation: Operation {
  let presentationContext: UIViewController
  let recordIDName: String
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(
    presentationContext: UIViewController,
    itemRecordID: String,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.presentationContext = presentationContext
      self.recordIDName = itemRecordID
      self.context = context
      self.database = database
      super.init()
      addObserver(NetworkObserver())
  }
  
  override func execute() {
    let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
    let item = Item.MR_findFirstByAttribute("recordIDName", withValue: recordIDName, inContext: context)
    
    //add to local database
    if let favorites = myPerson.valueForKey("favorites") as? NSSet {
      let newFavorites = NSSet(array: favorites.allObjects + [item])
      myPerson.setValue(newFavorites, forKey: "favorites")
    } else {
      myPerson.setValue(NSSet(object: item), forKey: "favorites")
    }
    
    //add to cloud
    
    //Swift 2.0
//    guard let allFavorites = myPerson.valueForKey("favorites") as? NSSet else {
//      print("Error: There was an issue in PostFavoriteOperation. MyProfile.Favorites are not an NSSet.")
//      let error = NSError(code: OperationErrorCode.ExecutionFailed)
//      finishWithError(error)
//      return
//    }
//    guard let myRecordIDName = myPerson.valueForKey("recordIDName") as? String else {
//      print("Error: myRecordIDName was not a String")
//      let error = NSError(code: OperationErrorCode.ExecutionFailed)
//      finishWithError(error)
//      return
//    }
    let allFavorites = myPerson.valueForKey("favorites") as! NSSet
    let myRecordIDName = myPerson.valueForKey("recordIDName") as! String

    var allReferences = [CKReference]()
    
    for favoriteItem in allFavorites.allObjects {
      if let itemObject = favoriteItem as? NSManagedObject {
        let itemObjectRecordIDName = itemObject.valueForKey("recordIDName") as! String
        let itemObjectRecordID = CKRecordID(recordName: itemObjectRecordIDName)
        let newRef = CKReference(recordID: itemObjectRecordID, action: CKReferenceAction.None)
        allReferences.append(newRef)
      } else {
        print("Error: Favorite Item was not NSManagedObject")
        let error = NSError(code: OperationErrorCode.ExecutionFailed)
        finishWithError(error)
      }
    }
    
    if allReferences.count == 0 {
      print("Error: All references were 0")
      let error = NSError(code: OperationErrorCode.ExecutionFailed)
      finishWithError(error)
      return
    }
    
    let myRecordID = CKRecordID(recordName: myRecordIDName)
    let myNewRecord = CKRecord(recordType: RecordTypes.User, recordID: myRecordID)
    myNewRecord.setObject(allReferences, forKey: "FavoriteItems")
    
    let saveMeOp = CKModifyRecordsOperation(recordsToSave: [myNewRecord], recordIDsToDelete: nil)
    saveMeOp.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, operationError) -> Void in
      
      if let mySavedRecordFavorites = savedRecords?.first?.valueForKey("FavoriteItems") as? [CKReference] {
        
        let itemsFromRecordIDs = mySavedRecordFavorites.map {
          Item.MR_findFirstOrCreateByAttribute("recordIDName", withValue: $0.recordID.recordName, inContext: self.context)
        }
        myPerson.setValue( NSSet(array: itemsFromRecordIDs), forKey: "favorites")
      } else {
        print("mySavedRecord did not have a FavoriteItems array")
      }
      
      self.context.MR_saveToPersistentStoreAndWait()
      self.finishWithError(operationError)
    }
    database.addOperation(saveMeOp)
    
  }
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      self.produceOperation(alert)
    }
  }
}
