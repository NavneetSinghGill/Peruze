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

/*


let person = Person.MR_findFirstByAttribute("recordIDName", withValue: personRecordIDName, inContext: context)
let uploadsPredicate = NSPredicate(format: "%@ == %@","owner.recordIDName", personRecordIDName)
let uploadFetch = Item.MR_fetchAllGroupedBy(nil, withPredicate: uploadsPredicate, sortedBy: nil, ascending: true)
do{
try uploadFetch.performFetch()
} catch {
return NSPredicate(value: false)
}

print(person.uploads?.allObjects)

//gather a list of references to send to the cloud kit server
var uploadRecordReferences = [CKReference]()
for upload in person.uploads!.allObjects where uploadFetch.fetchedObjects != nil {
if let uploadID = (upload as? Item)?.recordIDName {
print("RECORD ID NAME::::::" + "\(uploadID)")
//      let tempRecordID = CKRecordID(recordName: uploadID)
//      uploadRecordReferences.append(CKReference(recordID: tempRecordID, action: .None))
}
}


*/



/**
This class retrieves all of the specified user's exchanges. This is based on the user uploads.
If the specified user does not have any uploads, this will finish without retrieving or saving
any objects. Make sure to use the GetUploadsOperation before you call this operation.
For PROFILE section
*/
class GetAllParticipatingExchangesOperation: GroupOperation {
  
  init(personRecordIDName: String,
    status: ExchangeStatus? = nil,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      let personIsCreator = PersonIsCreator (
        personRecordIDName: personRecordIDName,
        status: status,
        database: database,
        context: context
      )
      let personIsRequestedFrom = PersonIsRequestedFrom (
        personRecordIDName: personRecordIDName,
        status: status,
        database: database,
        context: context
      )
      super.init(operations: [personIsCreator, personIsRequestedFrom])
  }
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if errors.first != nil {
      print("GetAllParticipatingExchangesOperation finished with error:")
      print(errors.first!)
    }
  }

}

private class PersonIsCreator: GetExchangesOperation {
  override func getPredicate() -> NSPredicate {
    let personIsCreator = NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: personRecordIDName))
    let statusPredicate = status == nil ? NSPredicate(value: true) : NSPredicate(format: "ExchangeStatus == %i", status!.rawValue)
    return NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, personIsCreator])
  }
}

private class PersonIsRequestedFrom: GetExchangesOperation {
  override func getPredicate() -> NSPredicate {
    let personIsBeingRequestedFrom = NSPredicate(format: "RequestedItemOwnerRecordIDName == %@", personRecordIDName)
    let statusPredicate = status == nil ? NSPredicate(value: true) : NSPredicate(format: "ExchangeStatus == %i", status!.rawValue)
    return NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, personIsBeingRequestedFrom])
  }
}

/**
Fetches only exchanges that are requested from you with the given exchange status
*/
class GetOnlyRequestedExchangesOperation: GetExchangesOperation {
  override func getPredicate() -> NSPredicate {
    let person = Person.MR_findFirstByAttribute("recordIDName", withValue: personRecordIDName, inContext: context)
    guard let uploads = person.uploads where uploads.count != 0 else {
      return NSPredicate(value: false)
    }

    //create predicate
    let personIsBeingRequestedFrom = NSPredicate(format: "RequestedItemOwnerRecordIDName == %@", personRecordIDName)
    let statusPredicate = NSPredicate(format: "ExchangeStatus == %i", status!.rawValue)
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, personIsBeingRequestedFrom])
    
    return compoundPredicate
  }
}

/**
This class is meant to be subclassed. Override the getPredicate() function to supply a specific
predicate to the operation. Otherwise, this will retrieve no exchanges.
*/
class GetExchangesOperation: Operation {
  let personRecordIDName: String
  let status: ExchangeStatus?
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
    status: ExchangeStatus? = nil,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personRecordIDName = personRecordIDName
      self.status = status
      self.database = database
      self.context = context
      super.init()
  }
  
  override func execute() {
    print("Hit " + __FUNCTION__ + " in " + __FILE__)
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //make sure the predicate is valid
    if getPredicate() == NSPredicate(value: false) {
      print("false predicate")
      finish()
      return
    }
    
    //create the query and the operation
    let getExchangesQuery = CKQuery(recordType: RecordTypes.Exchange, predicate: getPredicate())
    let getExchangesOperation = CKQueryOperation(query: getExchangesQuery)
    
    //handle returned objects
    getExchangesOperation.recordFetchedBlock = { (record) -> Void in
      
      //find or create the record
      let requestingPerson = Person.MR_findFirstByAttribute("recordIDName",
        withValue: self.personRecordIDName,
        inContext: self.context)
      let localExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName,
        inContext: self.context)
      
      //set creator
      if record.creatorUserRecordID?.recordName == "__defaultOwner__" {
        localExchange.creator = Person.MR_findFirstOrCreateByAttribute("me",
          withValue: true,
          inContext: self.context)
      } else {
        localExchange.creator = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: record.creatorUserRecordID?.recordName,
          inContext: self.context)
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
        localExchange.itemOffered = Item.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: itemOfferedReference.recordID.recordName,
          inContext: self.context)
      }
      
      //set item requested
      if let itemRequestedReference = record.objectForKey("RequestedItem") as? CKReference {
        localExchange.itemRequested = Item.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: itemRequestedReference.recordID.recordName,
          inContext: self.context)
      }
      
      //add this exchange to the requesting user's exchanges
      requestingPerson?.exchanges = requestingPerson?.exchanges?.setByAddingObject(localExchange)
      
      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    getExchangesOperation.queryCompletionBlock = { (cursor, error) -> Void in
      if error != nil { print("Get Exchanges Completed with Error: \(error)") }
      self.finishWithError(error)
    }
    
    //add that operation to the operationQueue of self.database
    self.database.addOperation(getExchangesOperation)
  }
  
  func getPredicate() -> NSPredicate {
    return NSPredicate(value: false)
  }
}



