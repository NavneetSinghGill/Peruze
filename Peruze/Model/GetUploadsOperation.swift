//
//  GetUploadsOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
/**
Retrieves the uploads of the specified person and stores them in the `uploads` property for that
`Person` object
*/
class GetUploadsOperation: GetItemOperation {
  let personIDName: String
  /**
  - parameter recordID: The user whose uploads need to be fetched
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data.
  */
  init(recordID: CKRecordID,
    database: CKDatabase,
    context: NSManagedObjectContext = managedConcurrentObjectContext) {
      self.personIDName = recordID.recordName
        let limit = 500
        super.init(database: database, context: context, resultLimit: limit)
  }
  
  override func getPredicate() -> NSPredicate {
    print("\n \(NSDate()) GetUploadItemOperation getPredicate()")
    return NSPredicate(format: "creatorUserRecordID == %@", CKRecordID(recordName: personIDName))
  }
  
}