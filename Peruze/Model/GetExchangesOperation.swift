//
//  GetExchangesOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord

/**
This class retrieves all of the specified user's exchanges. This is based on the user uploads.
If the specified user does not have any uploads, this will finish without retrieving or saving
any objects. Make sure to use the GetUploadsOperation before you call this operation.
For PROFILE section
*/
class GetAllParticipatingExchangesOperation: GetExchangesOperation {
  override func getPredicate() -> NSPredicate {
    let person = Person.findFirstByAttribute("recordIDName", withValue: personRecordIDName, inContext: context)
    guard let uploads = person.uploads where uploads.count != 0 else {
      return NSPredicate(value: false)
    }
    
    //gather a list of references to send to the cloud kit server
    let uploadRecordIDNames = uploads.map({ ($0 as? Item)?.recordIDName })
    var uploadRecordReferences = [CKReference]()
    for recordIDName in uploadRecordIDNames {
      if let recordIDName = recordIDName {
        let tempRecordID = CKRecordID(recordName: recordIDName)
        uploadRecordReferences.append(CKReference(recordID: tempRecordID, action: .None))
      }
    }
    
    //check for items
    if uploadRecordReferences.count == 0 {
      return NSPredicate(value: false)
    }
    
    /* Creating the Predicate
    1. Check if the person created the exchange O(n)
    2. Check if the RequestedItem is an item uploaded by the user O(n^2)
    3. Check if the OfferedItem is an item uploaded by the user O(n^2)
    4. Participant = 1. OR 2. OR 3.
    5. Check the status to make sure it equals the given status O(n)
    6. Final query predicate = 5. AND 4. */
    //1
    let personIsCreator = NSPredicate(format: "creatorUserID == %@", CKRecordID(recordName: personRecordIDName))
    //2
    let uploadInRequestedItem = NSPredicate(format: "RequestedItem IN %@", uploadRecordReferences)
    //3
    let uploadInOfferedItem = NSPredicate(format: "OfferedItem IN %@", uploadRecordReferences)
    //4
    let participantPredicate = NSCompoundPredicate.orPredicateWithSubpredicates([personIsCreator, uploadInRequestedItem, uploadInOfferedItem])
    //5
    let statusPredicate = NSPredicate(format: "ExchangeStatus == %i", status.rawValue)
    //6
    let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([statusPredicate, participantPredicate])
    
    return compoundPredicate
  }
}


/**
Fetches only exchanges that are requested from you with the given exchange status
*/
class GetOnlyRequestedExchangesOperation: GetExchangesOperation {
  override func getPredicate() -> NSPredicate {
    let person = Person.findFirstByAttribute("recordIDName", withValue: personRecordIDName, inContext: context)
    guard let uploads = person.uploads where uploads.count != 0 else {
      return NSPredicate(value: false)
    }
    
    //gather a list of references to send to the cloud kit server
    let uploadRecordIDNames = uploads.map({ ($0 as? Item)?.recordIDName })
    var uploadRecordReferences = [CKReference]()
    for recordIDName in uploadRecordIDNames {
      if let recordIDName = recordIDName {
        let tempRecordID = CKRecordID(recordName: recordIDName)
        uploadRecordReferences.append(CKReference(recordID: tempRecordID, action: .None))
      }
    }
    
    //check for items
    if uploadRecordReferences.count == 0 {
      return NSPredicate(value: false)
    }
    
    //create predicate
    let uploadInRequestedItem = NSPredicate(format: "RequestedItem IN %@", uploadRecordReferences)
    let statusPredicate = NSPredicate(format: "ExchangeStatus == %i", status.rawValue)
    let compoundPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([statusPredicate, uploadInRequestedItem])
    
    return compoundPredicate
  }
}

/**
This class is meant to be subclassed. Override the getPredicate() function to supply a specific
predicate to the operation. Otherwise, this will retrieve no exchanges.
*/
class GetExchangesOperation: Operation {
  let personRecordIDName: String
  let status: ExchangeStatus
  let database: CKDatabase
  let context: NSManagedObjectContext

  /**
  - parameter personRecordID: The `person` who is participating in these exchanges
  - parameter status: The `ExchangeStatus` of the exchanges you want to fetch
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data.
  */
  init(personRecordIDName: String,
    status: ExchangeStatus,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personRecordIDName = personRecordIDName
      self.status = status
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    
    //create the query and the operation
    let getExchangesQuery = CKQuery(recordType: RecordTypes.Exchange, predicate: getPredicate())
    let getExchangesOperation = CKQueryOperation(query: getExchangesQuery)
    
    //handle returned objects
    getExchangesOperation.recordFetchedBlock = { (record) -> Void in
      MagicalRecord.saveWithBlockAndWait({ (context) -> Void in
        
        //find or create the record
        let requestingPerson = Person.findFirstByAttribute("recordIDName",
          withValue: self.personRecordIDName,
          inContext: context)
        let localExchange = Exchange.findFirstOrCreateByAttribute("recordIDName",
          withValue: record.recordID.recordName,
          inContext: context)
        
        //set creator
        if let creatorIDName = record.creatorUserRecordID?.recordName {
          localExchange.creator = Person.findFirstOrCreateByAttribute("recordIDName",
            withValue: creatorIDName,
            inContext: context)
        }
        
        //set exchange status
        if let newExchangeStatus = record.objectForKey("ExchangeStatus") as? Int64 {
          localExchange.status = NSNumber(longLong: newExchangeStatus)
        }
        
        //set date
        if let newDate = record.objectForKey("ExchangeDate") as? NSDate {
          localExchange.date = localExchange.date ?? newDate
        }
        
        //set item offered
        if let itemOfferedReference = record.objectForKey("OfferedItem") as? CKReference {
          localExchange.itemOffered = Item.findFirstOrCreateByAttribute("itemOffered",
            withValue: itemOfferedReference.recordID.recordName,
            inContext: context)
        }
        
        //set item requested
        if let itemRequestedReference = record.objectForKey("RequestedItem") as? CKReference {
          localExchange.itemOffered = Item.findFirstOrCreateByAttribute("itemRequested",
            withValue: itemRequestedReference.recordID.recordName,
            inContext: context)
        }
        
        //add this exchange to the requesting user's exchanges
        requestingPerson?.exchanges = requestingPerson?.exchanges?.setByAddingObject(localExchange)

        context.saveToPersistentStoreAndWait()
      })
    }
    
    getExchangesOperation.queryCompletionBlock = { (cursor, error) -> Void in
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getExchangesOperation)
  }
  
  func getPredicate() -> NSPredicate {
    return NSPredicate(value: false)
  }
}




