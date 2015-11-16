//
//  GetCurrentUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/20/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

private enum CurrentUserOperationError: ErrorType {
  case CloudKitError(NSError)
}

class GetCurrentUserOperation: Operation {
  
  private let context: NSManagedObjectContext
  private let database: CKDatabase
  private let presentationContext: UIViewController
  internal var finishedBlock : (error :[NSError]) -> (Void)
  
  init(presentationContext: UIViewController, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    
    self.presentationContext = presentationContext
    self.database = database
    self.context = context
    self.finishedBlock = { error in }
    super.init()
    
    addObserver(NetworkObserver())
  }
  
  override func execute() {
    
    print("\(NSDate())\nExecute of Get Current User from iCloud Operation\n")
    let fetchUser = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    fetchUser.perRecordCompletionBlock = { (record, recordID, error) -> Void in
      print("\(NSDate())Fetched Current User from iCloud Operation \(record)")
      //make sure there were no errors
      if let error = error {
        print("GetCurrentUserOperation failed with error:")
        print(error)
        self.finishWithError(error)
        return
      }
      
      guard let record = record else {
        print("The record returned from the server was nil")
        return
      }
      
      //save the records to the local DB
      let person = Person.MR_findFirstOrCreateByAttribute("me",
        withValue: true,
        inContext: self.context)
      
      
      //set the returned properties
      let firstName  = (record.objectForKey("FirstName")  as? String)
      let lastName   = (record.objectForKey("LastName")   as? String)
      let facebookID = (record.objectForKey("FacebookID") as? String)
        
        
        if (person?.valueForKey("FacebookID") as? String) != facebookID {
            person.facebookID = nil
            person.firstName = nil
            person.lastName = nil
            person.image = nil
            self.context.MR_saveToPersistentStoreAndWait()
            self.finish()
            return
        }
        
        

      person.setValue(recordID!.recordName, forKey: "recordIDName")
      person.setValue(firstName, forKey: "firstName")
      person.setValue(lastName, forKey: "lastName")
      person.setValue(facebookID, forKey: "facebookID")
      
      //check for image property and set the data
      if let imageAsset = record.objectForKey("Image") as? CKAsset {
        let imageData = NSData(contentsOfURL: imageAsset.fileURL)
        person.setValue(imageData, forKey: "image")
      }
      
      //check for favorites
      if let favoriteReferences = record.objectForKey("FavoriteItems") as? [CKReference] {
        let favorites = favoriteReferences.map {
          Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: $0.recordID.recordName , inContext: self.context)
        }
        let favoritesSet = NSSet(array: favorites)
        person.setValue(favoritesSet, forKey: "favorites")
      }
      
      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
    
        
      self.finish()
    }
    
    //add operation to the cloud kit database
    fetchUser.qualityOfService = qualityOfService
    database.addOperation(fetchUser)
  }
  override func finished(errors: [NSError]) {
    
    let alert = AlertOperation(presentationContext: presentationContext)
    alert.title = "iCloud Error"
    
    
    if let firstError = errors.first {
        let errorCode : CKErrorCode = CKErrorCode(rawValue: firstError.code)!
      switch errorCode {
      case .NotAuthenticated :
        alert.message = "There was an error getting your user from iCloud. Make sure you're logged into iCloud in Settings and iCloud Drive is turned on for Peruze."
        break
      default:
        alert.message = "Getting your information with the server failed with the following error: " + firstError.localizedDescription
        break
      }
        alert.addCompletionBlock({Void in
            self.finishedBlock(error: errors)
        })
        produceOperation(alert)
    }
//    else {
//      alert.message = "There was an error getting your user from iCloud. Make sure you're logged into iCloud in Settings and iCloud Drive is turned on for Peruze."
//    }
    
  }
}