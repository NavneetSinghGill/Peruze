//
//  Person.swift
//  Peruze
//
//  Created by Phillip Trent on 7/18/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(Person)
class Person: NSManagedObject {
  class func personForRecord(record: CKRecord) -> Person {
    let person = Person()
    person.recordIDName = record.recordID.recordName
    person.firstName = record.objectForKey("FirstName") as? String
    person.lastName = record.objectForKey("LastName") as? String
    person.facebookID = record.objectForKey("FacebookID") as? String
    //fetch image
    if let url = (record.objectForKey("Image") as? CKAsset)?.fileURL {
      person.image = NSData(contentsOfURL: url)
    }
    return person
  }
  
}
