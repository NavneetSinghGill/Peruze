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

class GetChatsOperation: GroupOperation {
  let getExchangesOp: GetAllParticipatingExchangesOperation
  let getChatsOp: GetChatsForAcceptedExchangesOperation
  let getMessagesOp: GetAllMessagesForAllChats
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext, completion: (Void -> Void) = {}) {
    
    let myRecord = Person.MR_findFirstByAttribute("me", withValue: true)
    let myRecordIDName = myRecord.valueForKey("recordIDName") as? String
    
    /*
    This operation is made of 3 operations
    1. Get exchanges that the logged in user is a part
    of that have a completed status
    2. Get the chats that correspond to those exchanges
    3. Get the messages that correspond to those chats
    */
    
    getExchangesOp = GetAllParticipatingExchangesOperation(personRecordIDName: myRecordIDName!, database: database, context: context)
    getChatsOp = GetChatsForAcceptedExchangesOperation(database: database, context: context)
    getMessagesOp = GetAllMessagesForAllChats(database: database, context: context)
    
    let finishingOp = NSBlockOperation(block: completion)
    
    //add dependencies
    getMessagesOp.addDependency(getChatsOp)
    getChatsOp.addDependency(getExchangesOp)
    finishingOp.addDependencies([getExchangesOp, getChatsOp, getMessagesOp])
    
    super.init(operations: [getExchangesOp, getChatsOp, getMessagesOp, finishingOp])
  }
  
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if let firstError = errors.first where
      ( operation === getExchangesOp || operation === getChatsOp || operation === getMessagesOp ) {
        print("GetChatsOperation Failed With Error: \(firstError)")
    }
  }
}

class GetChatsForAcceptedExchangesOperation: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    
    //Get all accepted exchanges from the database
    let exchangesPredicate = NSPredicate(format: "status == %i && recordIDName != nil", ExchangeStatus.Accepted.rawValue)
    guard let acceptedExchanges = Exchange.MR_findAllSortedBy("recordIDName",
      ascending: true,
      withPredicate: exchangesPredicate,
      inContext: context) as? [NSManagedObject] else {
        print("Error: Accepted Exchanges were not [NSManagedObject]")
        self.finish()
        return
    }
    
    //Create CKReferences for all accepted exchanges
    let exchangeIDs = acceptedExchanges.map { $0.valueForKey("recordIDName") as? String }
    var exchangeReferences = [CKReference]()
    for id in exchangeIDs where id != nil {
      let recordID = CKRecordID(recordName: id!)
      let recordRef = CKReference(recordID: recordID, action: .None)
      exchangeReferences.append(recordRef)
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
      
      if let exchange = record.objectForKey("Exchange") as? CKReference {
        let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: exchange.recordID.recordName,
          inContext: self.context)
        localMessage.setValue(messageExchange, forKey:"exchange")
      }
      
      self.context.saveOnlySelfAndWait()
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

class GetAllMessagesForAllChats: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    
  }
}