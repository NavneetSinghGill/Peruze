//
//  GetPersonOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class GetPersonOperation: Operation {
  let personID: CKRecordID
  let database: CKDatabase
  let context: NSManagedObjectContext
  /**
  - parameter recordID: A valid recordIDName that corresponds to the person
  whom you wish to fetch
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data. The operation will internally
  construct a new `NSManagedObjectContext` that points
  to the same `NSPersistentStoreCoordinator` as the
  passed-in context.
  */
  init(recordID: CKRecordID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.personID = recordID
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    //figure out what keys need to be fetched
    let person = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: personID.recordName, inContext: context)
    var desiredKeys: [String] = []
    
    if (person.valueForKey("firstName") as? String) == nil {
      desiredKeys.append("FirstName")
    }
    
    if (person.valueForKey("lastName") as? String) == nil {
      desiredKeys.append("LastName")
    }
    
    if (person.valueForKey("image") as? NSData) == nil {
      desiredKeys.append("Image")
    }
    
    if (person.valueForKey("facebookID") as? String) == nil {
      desiredKeys.append("FacebookID")
    }
    
    desiredKeys.append("FavoriteItems")
    
    //if the person is complete, finish and return
    if desiredKeys.count == 0 {
      finish()
      return
    }
    
    //create operation for fetching relevant records
    let getPersonOperation = CKFetchRecordsOperation(recordIDs: [personID])
    getPersonOperation.desiredKeys = desiredKeys
    getPersonOperation.fetchRecordsCompletionBlock = { (recordsByID: [NSObject: AnyObject]!, opError: NSError!) -> Void in
      
      //add person to the database
      let keysArray = recordsByID.keys.array
      for key in keysArray {
        
        if let recordID = key as? CKRecordID {
          
          //fetch each person with the returned ID
          var localPerson = Person.MR_findFirstByAttribute("recordIDName", withValue: recordID, inContext: self.context)
          if localPerson == nil {
            localPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: self.context)
          }
          
          //set the returned properties
          localPerson.setValue(recordID.recordName, forKey: "recordIDName")
          /*
          if (localPerson.valueForKey("firstName") as? String) == nil {
          localPerson.firstName = recordsByID[recordID]!.objectForKey("FirstName") as? String
          }
          if (localPerson.valueForKey("lastName") as? String) == nil {
          localPerson.firstName = recordsByID[recordID]!.objectForKey("LastName") as? String
          }
          if (localPerson.valueForKey("facebookID") as? String) == nil {
          localPerson.firstName = recordsByID[recordID]!.objectForKey("FacebookID") as? String
          }
          //check for image property and set the data
          if let imageAsset = recordsByID[recordID]?.objectForKey("Image") as? CKAsset {
          localPerson.image = NSData(contentsOfURL: imageAsset.fileURL)
          }
          */
          self.context.MR_saveToPersistentStoreAndWait()
          
        }
        
      }
      //because the operations inside of the block wait, we can call finish outside of the block
      self.finish(GenericError.ExecutionFailed)
    }
    
    //add that operation to the operationQueue of self.database
    getPersonOperation.qualityOfService = NSQualityOfService.Utility
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
    
    //figure out what keys need to be fetched
    let missingPersonsPredicate = NSPredicate(value: true)//(format: "recordIDName != nil AND image == nil")
    
    let allMissingPersons = Person.MR_findAllWithPredicate(missingPersonsPredicate, inContext: context) as! [NSManagedObject]
    let allMissingPersonsRecordNameID = allMissingPersons.map { $0.valueForKey("recordIDName") as? String }
    let desiredKeys = ["FirstName", "LastName", "Image", "FacebookID"]
    var missingPersonsRecordIDs = [CKRecordID]()
    for recordIDName in allMissingPersonsRecordNameID {
      if recordIDName != nil {
        missingPersonsRecordIDs.append(CKRecordID(recordName: recordIDName!))
      }
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
        
        //fetch each person with the returned ID
        let recordID = recordID as! CKRecordID
        var localPerson: Person!
        if recordID.recordName == "__defaultOwner__" {
          localPerson = Person.MR_findFirstOrCreateByAttribute("me",
            withValue: true,
            inContext: self.context)
        } else {
          localPerson = Person.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: recordID.recordName,
            inContext: self.context)
        }
        
        let record = recordsByID![recordID]! as! CKRecord
        
        //set the returned properties
        if localPerson.valueForKey("firstName") as? String == nil {
          localPerson.setValue(record.objectForKey("FirstName") as? String, forKey: "firstName")
        }
        
        if localPerson.valueForKey("lastName") as? String == nil {
          localPerson.setValue(record.objectForKey("LastName") as? String, forKey: "lastName")
        }
        
        if localPerson.valueForKey("facebookID") as? String == nil {
          localPerson.setValue(record.objectForKey("FacebookID") as? String, forKey: "facebookID")
        }
        
          //check for image property and set the data
        if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
          localPerson.setValue( NSData(contentsOfURL: imageAsset.fileURL), forKey: "image")
        }
        
        self.context.MR_saveToPersistentStoreAndWait()
      }
      
      //because the operations inside of the block wait, we can call finish outside of the block
      self.finish(GenericError.ExecutionFailed)
      
    }
    
    //add that operation to the operationQueue of self.database
    getPersonOperation.qualityOfService = NSQualityOfService.Utility
    self.database.addOperation(getPersonOperation)
    
  }
}