//
//  RemoveFavoriteOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/19/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private enum RemoveFavoriteOperationError: ErrorType {
  case ExecutionFailed
}

//Removes the specified item from the local and cloud user's favorites
class RemoveFavoriteOperation: Operation {
  
  let presentationContext: UIViewController
  let recordIDName: String
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(
    presentationContext: UIViewController,
    itemRecordID: String,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
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
    
    //remove from local database
    if let favorites = myPerson.valueForKey("favorites") as? NSSet {
      let filteredFavorites = favorites.allObjects.filter { ($0.valueForKey("recordIDName") as! String) != (item.valueForKey("recordIDName") as! String) }
      let newFavorites = NSSet(array: filteredFavorites)
      myPerson.setValue(newFavorites, forKey: "favorites")
    } else {
      myPerson.setValue(nil, forKey: "favorites")
    }
    
    //add to cloud
    
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
        finish()
      }
    }
    
    let myRecordID = CKRecordID(recordName: myRecordIDName)
    let myNewRecord = CKRecord(recordType: RecordTypes.User, recordID: myRecordID)
    myNewRecord.setObject(allReferences, forKey: "FavoriteItems")
    
    let saveMeOp = CKModifyRecordsOperation(recordsToSave: [myNewRecord], recordIDsToDelete: nil)
    saveMeOp.savePolicy = CKRecordSavePolicy.ChangedKeys
    saveMeOp.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, operationError) -> Void in
      if operationError != nil {
        print("saveMeOp.modifyRecordsCompletionBlock in " + __FUNCTION__ + " in " + __FILE__ + " finished with error : \(operationError) ")
        self.finishWithError(operationError)
        return
      }
      
      print("       Here is my saved records      ")
      print(savedRecords?.first?.valueForKey("FavoriteItems"))
      print("     ")
      if let mySavedRecordFavorites = savedRecords?.first?.valueForKey("FavoriteItems") as? NSSet {
        if let savedRecordArray = mySavedRecordFavorites.allObjects as? [CKReference] {
          let itemsFromRecordIDs = savedRecordArray.map {
            Item.MR_findFirstOrCreateByAttribute("recordIDName", withValue: $0.recordID.recordName, inContext: self.context)
          }
          myPerson.setValue( NSSet(array: itemsFromRecordIDs), forKey: "favorites")
        } else {
          print("mySavedRecords is not a [CKReference]  ")
        }
      } else {
        print("mySavedRecord is not an NSSet")
      }
      
      self.context.MR_saveToPersistentStoreAndWait()
      self.finish()
    }
    saveMeOp.qualityOfService = qualityOfService
    database.addOperation(saveMeOp)
    
  }
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "Oh no!"
      alert.message = "There was an issue with favoriting an item. A recent favorite may not have been saved."
      produceOperation(alert)
    }
  }
}
