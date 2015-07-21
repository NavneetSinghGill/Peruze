//
//  GetCurrentUserOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/20/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import MagicalRecord

class GetCurrentUserOperation: Operation {
  let context: NSManagedObjectContext
  let database: CKDatabase
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    print("init operation")
    super.init()
  }
  override func execute() {
    print("execute of Get Current User Operation")
    let fetchUser = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    
    fetchUser.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      
      //make sure there were no errors
      if error != nil {
        self.finishWithError(error)
        return
      }
      
      //make sure there were records
      if recordsByID == nil {
        self.finish()
        return
      }
      
      //save the records to the local DB
      MagicalRecord.saveWithBlockAndWait { (context) -> Void in
        let recordID = recordsByID!.keys.first!
        let person = Person.MR_findFirstOrCreateByAttribute("recordIDName",
          withValue: recordID.recordName,
          inContext: context) as Person!
        
        //set the returned properties
        person.me = true
        person.recordIDName = recordID.recordName
        person.firstName  = person.firstName  ?? recordsByID![recordID]!.objectForKey("FirstName")  as? String
        person.lastName   = person.lastName   ?? recordsByID![recordID]!.objectForKey("LastName")   as? String
        person.facebookID = person.facebookID ?? recordsByID![recordID]!.objectForKey("FacebookID") as? String
        
        //check for image property and set the data
        if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
          person.image = person.image ?? NSData(contentsOfURL: imageAsset.fileURL)
        }
        
        //check for favorites
        if let favoriteReferences = recordsByID?[recordID]?.objectForKey("FavoriteItems") as? [CKReference] {
          let favorites = favoriteReferences.map {
            Item.MR_findFirstOrCreateByAttribute("recordIDName",
              withValue: $0.recordID.recordName , inContext: context)
          }
          person.favorites = NSSet(array: favorites)
        }
      }
      self.finish()
    }
    
    //add operation to the cloud kit database
    database.addOperation(fetchUser)
  }
}