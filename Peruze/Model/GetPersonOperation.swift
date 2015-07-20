//
//  GetPersonOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord

class GetPersonOperation: Operation {
  let personID: CKRecordID
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(recordID: CKRecordID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.personID = recordID
    self.database = database
    self.context = context
    super.init()
  }
  /**
  - parameter itemIDName: A valid recordIDName whose owner corresponds to the person
              that you wish to fetch
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
              basis for importing data. The operation will internally
              construct a new `NSManagedObjectContext` that points
              to the same `NSPersistentStoreCoordinator` as the
              passed-in context.
  */
  init(itemIDName: String, database: CKDatabase, context: NSManagedObjectContext? = managedConcurrentObjectContext) {
    self.database = database
    self.context = context!
    let item = Item.findFirstByAttribute("recordIDName", withValue: itemIDName)
    personID = CKRecordID(recordName: item.owner!.recordIDName!)
    super.init()
  }
  
  override func execute() {
    //figure out what keys need to be fetched
    let person = Person.findFirstOrCreateByAttribute("recordIDName", withValue: personID.recordName, inContext: context)
    var desiredKeys = [String]()
    desiredKeys += (person.firstName  == nil ? ["FirstName"]  : [])
    desiredKeys += (person.lastName   == nil ? ["LastName"]   : [])
    desiredKeys += (person.image      == nil ? ["Image"]      : [])
    desiredKeys += (person.facebookID == nil ? ["FacebookID"] : [])
    desiredKeys += ["FavoriteItems"]
    
    //if the person is complete, finish and return
    if desiredKeys.count == 0 {
      finish()
      return
    }
    
    //create operation for fetching relevant records
    let getPersonOperation = CKFetchRecordsOperation(recordIDs: [personID])
    getPersonOperation.desiredKeys = desiredKeys
    getPersonOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      if error != nil {
        self.finishWithError(error)
      } else {
        //add person to the database
        MagicalRecord.saveWithBlockAndWait { (context) -> Void in
          for recordID in recordsByID!.keys {
            
            //fetch each person with the returned ID
            let localPerson = Person.findFirstByAttribute("recordIDName", withValue: recordID, inContext: context)
            
            //set the returned properties
            localPerson.firstName  = localPerson.firstName  ?? recordsByID![recordID]!.objectForKey("FirstName")  as? String
            localPerson.lastName   = localPerson.lastName   ?? recordsByID![recordID]!.objectForKey("LastName")   as? String
            localPerson.facebookID = localPerson.facebookID ?? recordsByID![recordID]!.objectForKey("FacebookID") as? String
            
            //check for image property and set the data
            if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
              localPerson.image = localPerson.image ?? NSData(contentsOfURL: imageAsset.fileURL)
            }
            
            if let favoriteReferences = recordsByID?[recordID]?.objectForKey("FavoriteItems") as? [CKReference] {
              let favorites = favoriteReferences.map {
                Item.findFirstOrCreateByAttribute("recordIDName",
                  withValue: $0.recordID.recordName , inContext: context)
              }
              localPerson.favorites = NSSet(array: favorites)
            }
            
            //save the context
            context.saveToPersistentStoreAndWait()
          }
        }
        
        //because the operations inside of the block wait, we can call finish outside of the block
        self.finish()
      }
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getPersonOperation)
  }
}