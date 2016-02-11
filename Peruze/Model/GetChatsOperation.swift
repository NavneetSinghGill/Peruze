//
//  GetChatsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

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
        logw("GetChatsOperation Failed With Error: \(firstError)")
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
    messagesQueryOp.recordFetchedBlock = { (record: CKRecord!) -> Void in
      
      let localMessage = Message.MR_findFirstOrCreateByAttribute("recordIDName",
        withValue: record.recordID.recordName, inContext: self.context)
      
      if let messageText = record.objectForKey("Text") as? String {
        localMessage.setValue(messageText, forKey: "text")
        if messageText == "xc"{
            
        }
      }
      
      if let messageImage = record.objectForKey("Image") as? CKAsset {
        localMessage.setValue(NSData(contentsOfURL: messageImage.fileURL), forKey: "image")
      }
      
      localMessage.setValue(record.objectForKey("Date") as? NSDate, forKey: "date")
      
      if let exchange = record.objectForKey("Exchange") as? CKReference {
        let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: exchange.recordID.recordName,
          inContext: self.context)
        if messageExchange.valueForKey("dateOfLatestChat") == nil || (record.valueForKey("modificationDate") as! NSDate).timeIntervalSince1970 > (messageExchange.valueForKey("dateOfLatestChat") as! NSDate).timeIntervalSince1970 {
            messageExchange.setValue(record.valueForKey("modificationDate"), forKey: "dateOfLatestChat")
//            messageExchange.setValue(false, forKey: "isRead")
        }
        localMessage.setValue(messageExchange, forKey: "exchange")
      }
      
        if let receiverRecordIDName = record.objectForKey("ReceiverRecordIDName") as? String {
            localMessage.setValue(receiverRecordIDName, forKey: "receiverRecordIDName")
        }
        
        if let senderRecordIDName = record.objectForKey("SenderRecordIDName") as? String {
            localMessage.setValue(senderRecordIDName, forKey: "senderRecordIDName")
        }
        
      if record.creatorUserRecordID?.recordName == "__defaultOwner__" {
        let sender = Person.MR_findFirstOrCreateByAttribute("me",
          withValue: true,
          inContext: self.context)
        localMessage.setValue(sender, forKey: "sender")
      } else {
        let sender = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: record.creatorUserRecordID?.recordName,
          inContext: self.context)
        localMessage.setValue(sender, forKey: "sender")
      }
      
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    //Finish this operation
    messagesQueryOp.queryCompletionBlock = { (cursor, error) -> Void in
      if let error = error {
        logw("Get Chats For Accepted Exchanges Operation Finished with error: ")
        logw("\(error)")
      }
      self.finishWithError(error)
    }
    
    //add the operation to the database
    messagesQueryOp.qualityOfService = qualityOfService
    database.addOperation(messagesQueryOp)
  }
}

