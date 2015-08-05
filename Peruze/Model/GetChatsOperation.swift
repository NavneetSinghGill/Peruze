//
//  GetChatsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord
///Retrieves all of the chats and their subsequent messages for the loggen in user
class GetChatsOperation: GroupOperation {
  let getExchangesOp: GetAllParticipatingExchangesOperation
  let getMessagesOp: GetMessagesForAcceptedExchangesOperation
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext, completion: (Void -> Void) = {}) {
    
    let myRecord = Person.MR_findFirstByAttribute("me", withValue: true)
    let myRecordIDName = myRecord.valueForKey("recordIDName") as? String
    
    /*
    This operation is made of 2 operations
    1. Get exchanges that the logged in user is a part of that have a completed status
    2. Get the messages that correspond to those exchanges
    */
    
    getExchangesOp = GetAllParticipatingExchangesOperation (
      personRecordIDName: myRecordIDName!,
      status: ExchangeStatus.Accepted,
      database: database,
      context: context
    )
    
    getMessagesOp = GetMessagesForAcceptedExchangesOperation(database: database, context: context)
    
    let finishingOp = NSBlockOperation(block: completion)
    
    //add dependencies
    getMessagesOp.addDependency(getExchangesOp)
    finishingOp.addDependencies([getExchangesOp, getMessagesOp])
    
    super.init(operations: [getExchangesOp, getMessagesOp, finishingOp])
  }
  
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if let firstError = errors.first where
      ( operation === getExchangesOp || operation === getMessagesOp ) {
        print("GetChatsOperation Failed With Error: \(firstError)")
    }
  }
  
}

class GetMessagesForAcceptedExchangesOperation: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    
    //Get all accepted exchanges from the database
    let exchangesPredicate = NSPredicate(format: "status = %@"/*" && recordIDName != nil"*/, NSNumber(integer: ExchangeStatus.Accepted.rawValue))
    
    //Swift 2.0
    //    guard let acceptedExchanges = Exchange.MR_findAllSortedBy("recordIDName",
    //      ascending: true,
    //      withPredicate: exchangesPredicate,
    //      inContext: context) as? [NSManagedObject] else {
    //        print("Error: Accepted Exchanges were not [NSManagedObject]")
    //        self.finish()
    //        return
    //    }
    
    let acceptedExchanges = Exchange.MR_findAllSortedBy("recordIDName",
      ascending: true,
      withPredicate: exchangesPredicate,
      inContext: context) as! [NSManagedObject]
    
    
    //Create CKReferences for all accepted exchanges
    let exchangeIDs = acceptedExchanges.map { $0.valueForKey("recordIDName") as? String }
    var exchangeReferences = [CKReference]()
    
    //Swift 2.0
    //for id in exchangeIDs where id != nil {
    for id in exchangeIDs {
      if id != nil {
        let recordID = CKRecordID(recordName: id!)
        let recordRef = CKReference(recordID: recordID, action: .None)
        exchangeReferences.append(recordRef)
      }
    }
    
    if exchangeReferences.count == 0 {
      self.finish()
      return
    }
    
    //Query the server for messages that correspond to those CKReferences
    let messagesPredicate = NSPredicate(format: "Exchange IN %@", exchangeReferences)
    let messagesQuery = CKQuery(recordType: RecordTypes.Message, predicate: messagesPredicate)
    let messagesQueryOp = CKQueryOperation(query: messagesQuery)
    
    
    //Add the messages to the database and save the context
    messagesQueryOp.recordFetchedBlock = { (record) -> Void in
      
      let localMessage = Message.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      
      if let messageText = record.objectForKey("Text") as? String {
        localMessage.text = messageText
      }
      
      if let messageImage = record.objectForKey("Image") as? CKAsset {
        localMessage.image = NSData(contentsOfURL: messageImage.fileURL)
      }
      
      localMessage.date = record.objectForKey("Date") as? NSDate
      
      if let exchange = record.objectForKey("Exchange") as? CKReference {
        let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: exchange.recordID.recordName,
          inContext: self.context)
        localMessage.exchange = messageExchange
      }
      
      if record.creatorUserRecordID?.recordName == "__defaultOwner__" {
        localMessage.sender = Person.MR_findFirstOrCreateByAttribute("me",
          withValue: true,
          inContext: self.context)
      } else {
        localMessage.sender = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: record.creatorUserRecordID?.recordName,
          inContext: self.context)
      }
      
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //Finish this operation
    messagesQueryOp.queryCompletionBlock = { (cursor, error) -> Void in
      if error != nil {
        print("Get Chats For Accepted Exchanges Operation Finished with error: ")
        print(error)
      }
      self.finishWithError(error)
    }
    
    //add the operation to the database
    database.addOperation(messagesQueryOp)
  }
}

