//
//  CloudKitOperations.swift
//  Peruse
//
//  Created by Phillip Trent on 7/11/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation
import CloudKit
import AsyncOpKit

class iCloudAvailability: AsyncOperation {
  var accountStatus: CKAccountStatus?
  override func main() {
    if cancelled { finish(); return }
    //get account status
    CKContainer.defaultContainer().accountStatusWithCompletionHandler { (status, error) -> Void in
      self.accountStatus = status
      self.error = error
      self.finish()
    }
  }
}

//MARK: - User Profile
class FetchFullProfileForUserRecordID: AsyncOperation {
  var person: Person = Person()
  private let recordID: CKRecordID
  private let desiredKeys: [String]?
  private let publicDB = CKContainer.defaultContainer().publicCloudDatabase
  private let currentQ = NSOperationQueue.currentQueue() ?? NSOperationQueue.mainQueue()
  init(recordID: CKRecordID, desiredKeys: [String]? = nil) {
    self.recordID = recordID
    //var modifiedKeys = (desiredKeys ?? []) + ["FavoriteItems"]
    self.desiredKeys = nil
    super.init()
  }
  override func main() {
    //check for iCloud Account Availability
    let availability = iCloudAvailability()
    
    //make reference object for recordID
    let recordReference = CKReference(recordID: recordID, action: CKReferenceAction.None)

    //create query completion block
    let queryCompletionBlock = { (queryCursor: CKQueryCursor?, error: NSError?) -> Void in
      if error != nil {
        print("Error: \(error!.localizedDescription). \(error!.localizedFailureReason)")
        self.error = error
        self.cancel()
        return
      }
    }
    
    //get user record
    let userRecordFetch = FetchUserRecordWithID(recordID: recordID, desiredKeys: desiredKeys)
    userRecordFetch.completionHandler = { (operation) -> Void in
      if operation.error != nil {
        self.error = operation.error
        self.cancel()
        self.finish()
        return
      } else if let op = operation as? FetchUserRecordWithID {
        self.person.updatePersonWithRecord(op.record!)
      }
    }
    
    //get exchanges that are completed
    let exchangePredicate = NSPredicate(format: "creatorUserRecordID == %@ && ExchangeStatus == \(ExchangeStatus.Completed.rawValue)", recordID)
    let exchangeQuery = CKQuery(recordType: RecordTypes.Exchange, predicate: exchangePredicate)
    let exchangeOp = CKQueryOperation(query: exchangeQuery)
    exchangeOp.queryCompletionBlock = queryCompletionBlock
    exchangeOp.recordFetchedBlock = { record -> Void in
      print("exchange returned data with record: \(record)")
      self.person.completedExchanges.append(Exchange(record: record, database: self.publicDB))
    }
    
    //get favorites
    let favoritesOp = FetchDependencyFavorites()
    favoritesOp.completionHandler = { (operation) -> Void in
      if let fetchFavorites = operation as? FetchDependencyFavorites {
        self.person.favorites = fetchFavorites.favorites.map({ Item(record: $0, database: self.publicDB) })
      }
    }
    
    //get reviews
    let reviewPredicate = NSPredicate(format: "UserBeingReviewed == %@", recordReference)
    let reviewQuery = CKQuery(recordType: RecordTypes.Review, predicate: reviewPredicate)
    let reviewOp = CKQueryOperation(query: reviewQuery)
    reviewOp.queryCompletionBlock = queryCompletionBlock
    reviewOp.recordFetchedBlock = { record -> Void in
      print("review returned data with record: \(record)")
      self.person.reviews.append(Review(record: record, database: self.publicDB))
    }
    
    //get uploads
    let uploadPredicate = NSPredicate(format: "creatorUserRecordID == %@", recordID)
    let uploadQuery = CKQuery(recordType: RecordTypes.Item, predicate: uploadPredicate)
    let uploadOp = CKQueryOperation(query: uploadQuery)
    uploadOp.queryCompletionBlock = queryCompletionBlock
    uploadOp.recordFetchedBlock = { record -> Void in
      print("upload returned data with record: \(record)")
      self.person.uploads.append(Item(record: record, database: self.publicDB))
    }
    
    //finish operation
    let finishOperation = NSBlockOperation {
      self.finish()
      print("Get Full Profile For User Record Finished Successfully")
    }
    
    //add dependencies
    userRecordFetch.addDependency(availability)
    exchangeOp.addDependency(userRecordFetch)
    favoritesOp.addDependency(userRecordFetch)
    reviewOp.addDependency(userRecordFetch)
    uploadOp.addDependency(userRecordFetch)
    finishOperation.addDependency(userRecordFetch)
    finishOperation.addDependency(exchangeOp)
    finishOperation.addDependency(favoritesOp)
    finishOperation.addDependency(reviewOp)
    finishOperation.addDependency(uploadOp)
    
    //add to operation queue
    currentQ.addOperation(availability)
    currentQ.addOperation(userRecordFetch)
    publicDB.addOperation(exchangeOp)
    currentQ.addOperation(favoritesOp)
    publicDB.addOperation(reviewOp)
    publicDB.addOperation(uploadOp)
    currentQ.addOperation(finishOperation)
    
  }
}

/**
Operation to fetch the record for the user with the given RecordID. The record is stored in a
'record' property.
*/
class FetchUserRecordWithID: AsyncOperation {
  var record: CKRecord?
  private let recordID: CKRecordID
  private let desiredKeys: [String]?
  
  init(recordID: CKRecordID, desiredKeys: [String]? = nil) {
    self.recordID = recordID
    self.desiredKeys = desiredKeys
    super.init()
  }
  override func main() {
    let userRecordFetch = CKFetchRecordsOperation(recordIDs: [recordID])
    userRecordFetch.desiredKeys = desiredKeys
    userRecordFetch.perRecordCompletionBlock = { (record, recordID, error) -> Void in
      print("user record fetch complete with recordID: \(recordID)")
      //error handling
      if error != nil {
        self.error = error
        self.finish()
        return
      }
      if recordID == self.recordID {
        self.record = record
      }
    }
    userRecordFetch.fetchRecordsCompletionBlock = { (_, error) -> Void in
      if error != nil {
        self.error = error
        self.finish()
        return
      } else {
        self.finish()
      }
    }
    CKContainer.defaultContainer().publicCloudDatabase.addOperation(userRecordFetch)
  }
}


/**
Operation to fetch the favorites from the Favorites array of a user. There should only be one
dependency for this operation that has a public 'record' property that is of type RecordTypes.User.
If there is more than one dependency with a User 'record' property or there are no dependencies with
a User 'record' property, this will crash the program.
*/
class FetchDependencyFavorites: AsyncOperation {
  private var record: CKRecord?
  var favorites = [CKRecord]()
  
  override func main() {
    for object in dependencies {
      //make sure that the record is in dependencies
      if object.respondsToSelector("record"){
        if let record = object.record?() as? CKRecord {
          if record.recordType == RecordTypes.User {
            assert(self.record == nil, "FetchDependencyFavorites has more than one dependency with a User Record")
            self.record = record
          }
        }
      }
    }
    assert(self.record != nil, "FetchDependencyFavorites instance does not have a dependency with a User Record")
    
    //create favorite references operation if the record fetched favorites
    if let favoriteReferences = record!.objectForKey("Favorites") as? [CKReference] {
      //get the ids from the CKReference object array
      let favoriteIDs = favoriteReferences.map({ $0.recordID })
      //create an operation to fetch the favorites
      let favoritesFetch = CKFetchRecordsOperation(recordIDs: favoriteIDs)
      //add completion handler
      favoritesFetch.fetchRecordsCompletionBlock = { (recordsByRecordID, operationError) -> Void in
        print("fetched favorites with records \(recordsByRecordID)")
        //check for an error
        if self.error != nil {
          self.error = operationError
        } else {
          //set the favorites
          self.favorites = [CKRecord](recordsByRecordID!.values)
        }
        self.finish()
      }
      CKContainer.defaultContainer().publicCloudDatabase.addOperation(favoritesFetch)
    } else {
      //if the record does not have a favorites object
      print("The record passed to fetch dependency favorites does not have a favorites object")
      finish()
    }
  }
  
  
}


