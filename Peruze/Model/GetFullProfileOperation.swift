//
//  GetFullProfileOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

///A group operation to fetch all aspects of a user's profile
class GetFullProfileOperation: GroupOperation {
  
  //MARK: - Properties
  let fetchPersonOperation:    GetPersonOperation
  let fetchReviewsOperation:   GetReviewsOperation
  let fetchUploadsOperation:   GetUploadsOperation
  let fetchExchangesOperation: GetAllParticipatingExchangesOperation
  
  private var hasProducedAlert = false
  
  /**
  - parameter personRecordID: The record id of the person whose profile you would lie to fetch
  
  - parameter context: The `NSManagedObjectContext` into which the parsed
  Earthquakes will be imported.
  
  - parameter completionHandler: The handler to call after downloading and
  parsing are complete. This handler will be
  invoked on an arbitrary queue.
  */
  init(personRecordID: CKRecordID,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase,
    completionHandler: Void -> Void) {
    
    /*
    This operation is made of four child operations:
    1. The operation to download the person
    2. The operation to download the person's reviews
    3. The operation to download the person's uploads
    4. The operation to download the person's exchanges
    5. Finishing operation that holds the completion block
    */
    fetchPersonOperation = GetPersonOperation(recordID: personRecordID, database: database , context: context)
      fetchPersonOperation.completionBlock = {
        logw("Finished FetchPersonOperation")
//        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "FetchedPerson", object: nil, userInfo: nil))
      }
    fetchReviewsOperation = GetReviewsOperation(recordID: personRecordID, database: database, context: context)
      fetchReviewsOperation.completionBlock = {
        logw("Finished fetchReviewsOperation")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "FetchedPersonReviews", object: nil, userInfo: nil))
      }
    fetchUploadsOperation = GetUploadsOperation(recordID: personRecordID, database: database, context: context)
      fetchUploadsOperation.completionBlock = {
        logw("\n \(NSDate()) \nFinished fetchUploadsOperation")
//        let recordId : String = personRecordID.recordName
//        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "FetchedPersonUploads", object: recordId, userInfo: nil))
      }
    fetchExchangesOperation = GetAllParticipatingExchangesOperation(personRecordIDName: personRecordID.recordName,
      status: ExchangeStatus.Completed, database: database, context: context)
      fetchExchangesOperation.completionBlock = {
        logw("Finished fetchExchangesOperation")
//        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "FetchedPersonExchanges", object: nil, userInfo: nil))
      }
    
    let finishOperation = NSBlockOperation(block: completionHandler)
    
    // These operations must be executed in order
    fetchReviewsOperation.addDependency(fetchPersonOperation)
    fetchUploadsOperation.addDependency(fetchPersonOperation)
    fetchExchangesOperation.addDependencies([fetchUploadsOperation, fetchPersonOperation])
    finishOperation.addDependencies([fetchPersonOperation, fetchReviewsOperation, fetchUploadsOperation, fetchExchangesOperation])
    
    super.init(operations: [fetchPersonOperation, fetchReviewsOperation, fetchUploadsOperation, fetchExchangesOperation, finishOperation])
    
    name = "Get Full Profile"
  }
  override func operationDidFinish(operation: NSOperation, withErrors errors: [NSError]) {
    if let firstError = errors.first {
      logw("Get Full Profile Operation Failed With Error: \(firstError)")
      //produceAlert(firstError)
    }
  }
  private func produceAlert(error: NSError) {
    /*
    We only want to show the first error, since subsequent errors might
    be caused by the first.
    */
    if hasProducedAlert { return }
    
    let alert = AlertOperation()
    let errorReason = (error.domain, error.code, (error.userInfo[OperationConditionKey] as? String))
    
    // These are examples of errors for which we might choose to display an error to the user
    // TODO: Add to these when you get time
    
    let failedJSON = (NSCocoaErrorDomain, NSPropertyListReadCorruptError, nil as String?)
    
    produceOperation(alert)
    hasProducedAlert = true
  }
}

