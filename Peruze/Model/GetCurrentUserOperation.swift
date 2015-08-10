//
//  GetCurrentUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/20/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class GetCurrentUserOperation: Operation {
  
  private let context: NSManagedObjectContext
  private let database: CKDatabase
  private let presentationContext: UIViewController
  
  init(presentationContext: UIViewController, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    
    self.presentationContext = presentationContext
    self.database = database
    self.context = context
    super.init()
    
    addObserver(NetworkObserver())
    addCondition(CloudContainerCondition(container: CKContainer.defaultContainer()))
    
  }
  override func execute() {
    
    print("execute of Get Current User Operation")
    let fetchUser = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    
    fetchUser.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      
      //make sure there were no errors
      if error != nil {
        print("GetCurrentUserOperation failed with error:")
        print(error)
        self.finishWithError(error)
        return
      }
      
      //make sure there were records
      if recordsByID == nil {
        let error = NSError(code: OperationErrorCode.ExecutionFailed)
        self.finishWithError(error)
        return
      }
      
      //save the records to the local DB
      let recordID = recordsByID!.keys.first!
      let person = Person.MR_findFirstOrCreateByAttribute("me",
        withValue: true,
        inContext: self.context)
      
      
      //set the returned properties
      person.recordIDName = (recordID as! CKRecordID).recordName
      person.firstName  = (person.valueForKey("firstName") as? String) ?? (recordsByID![recordID]!.objectForKey("FirstName")  as? String)
      person.lastName   = (person.valueForKey("lastName") as? String) ?? (recordsByID![recordID]!.objectForKey("LastName")   as? String)
      person.facebookID = (person.valueForKey("facebookID")  as? String) ?? (recordsByID![recordID]!.objectForKey("FacebookID") as? String)
      
      //check for image property and set the data
      if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
        person.image = person.image ?? NSData(contentsOfURL: imageAsset.fileURL)
      }
      
      //check for favorites
      if let favoriteReferences = recordsByID?[recordID]?.objectForKey("FavoriteItems") as? [CKReference] {
        let favorites = favoriteReferences.map {
          Item.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: $0.recordID.recordName , inContext: self.context)
        }
        person.favorites = NSSet(array: favorites)
      }
      
      //save the context
      self.context.MR_saveToPersistentStoreAndWait()
      self.finish()
    }
    
    //add operation to the cloud kit database
    database.addOperation(fetchUser)
  }
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "iCloud Error"
      alert.message = "There was an error getting your user from iCloud. Make sure you're logged into iCloud in Settings and iCloud Drive is turned on for Peruze."
      produceOperation(alert)
    }
  }
}