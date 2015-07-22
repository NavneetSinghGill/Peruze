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
    let item = Item.MR_findFirstByAttribute("recordIDName", withValue: itemIDName)
    personID = CKRecordID(recordName: item.owner!.recordIDName!)
    super.init()
  }
  
  override func execute() {
    
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
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
            let localPerson = Person.MR_findFirstByAttribute("recordIDName", withValue: recordID, inContext: context)
            
            //set the returned properties
            localPerson.recordIDName = recordID.recordName
            localPerson.firstName  = localPerson.firstName  ?? recordsByID![recordID]!.objectForKey("FirstName")  as? String
            localPerson.lastName   = localPerson.lastName   ?? recordsByID![recordID]!.objectForKey("LastName")   as? String
            localPerson.facebookID = localPerson.facebookID ?? recordsByID![recordID]!.objectForKey("FacebookID") as? String
            
            //check for image property and set the data
            if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
              localPerson.image = localPerson.image ?? NSData(contentsOfURL: imageAsset.fileURL)
            }
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


class GetAllPersonsWithMissingData: Operation {
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  override func execute() {
    print("execute person fetch")
    
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //figure out what keys need to be fetched
    let missingPersonsPredicate = NSPredicate(value: true)//(format: "recordIDName != nil AND image == nil")
    guard let allMissingPersons = Person.MR_findAllWithPredicate(missingPersonsPredicate, inContext: context) as? [NSManagedObject] else {
      print("Get All Persons With Missing Data Finished Prematurely")
      self.finish()
      return
    }
    let allMissingPersonsRecordNameID = allMissingPersons.map { $0.valueForKey("recordIDName") as? String }
    let desiredKeys = ["FirstName", "LastName", "Image", "FacebookID"]
    var missingPersonsRecordIDs = [CKRecordID]()
    for recordIDName in allMissingPersonsRecordNameID where recordIDName != nil {
      missingPersonsRecordIDs.append(CKRecordID(recordName: recordIDName!))
    }
    
    if missingPersonsRecordIDs.count == 0 {
      self.finish()
      return
    }
    
    //create operation for fetching relevant records
    let getPersonOperation = CKFetchRecordsOperation(recordIDs: missingPersonsRecordIDs)
    getPersonOperation.desiredKeys = desiredKeys
    getPersonOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      if error != nil {
        print("Get All Persons With Missing Data Finished With Error: \(error!)")
        
      }
      for recordID in recordsByID!.keys {
      //add person to the database
      MagicalRecord.saveWithBlockAndWait { (context) -> Void in
        
          //fetch each person with the returned ID
          let localPerson = Person.MR_findFirstByAttribute("recordIDName", withValue: recordID.recordName, inContext: context)
          
          //set the returned properties
          localPerson.recordIDName = recordID.recordName
          localPerson.firstName  = localPerson.firstName  ?? recordsByID![recordID]!.objectForKey("FirstName")  as? String
          localPerson.lastName   = localPerson.lastName   ?? recordsByID![recordID]!.objectForKey("LastName")   as? String
          localPerson.facebookID = localPerson.facebookID ?? recordsByID![recordID]!.objectForKey("FacebookID") as? String
          
          //check for image property and set the data
          if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
            localPerson.image = localPerson.image ?? NSData(contentsOfURL: imageAsset.fileURL)
          }
          print("Person recordIDName: \(localPerson.recordIDName)")
          print("Person firstName: \(localPerson.firstName)")
          print("Person lastName: \(localPerson.lastName)")
          print("Person facebookID: \(localPerson.facebookID)")
        }
      }
      
      //because the operations inside of the block wait, we can call finish outside of the block
      self.finishWithError(error)
      
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getPersonOperation)
  }
}