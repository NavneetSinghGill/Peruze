//
//  GetPersonOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class GetPersonOperation: Operation {
  let personID: CKRecordID
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(recordID: CKRecordID, database: CKDatabase, context: NSManagedObjectContext? = managedConcurrentObjectContext) {
    self.personID = recordID
    self.database = database
    self.context = context!
    super.init()
  }
  /**
    - parameter itemIDName: A valid recordIDName whose owner corresponds to the person
                that you wish to fetch
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
    let person = Person.findFirstByAttribute("recordIDName", withValue: personID.recordName)
    var desiredKeys = [String]()
    desiredKeys = desiredKeys + (person.firstName == nil ? ["FirstName"] : [])
    desiredKeys = desiredKeys + (person.lastName == nil ? ["LastName"] : [])
    desiredKeys = desiredKeys + (person.image == nil ? ["Image"] : [])
    desiredKeys = desiredKeys + (person.facebookID == nil ? ["FacebookID"] : [])
    
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
        
        
        
        self.finish()
      }
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getPersonOperation)
  }
}