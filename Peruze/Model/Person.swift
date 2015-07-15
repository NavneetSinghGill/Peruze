//
//  Person.swift
//  Peruse
//
//  Created by Phillip Trent on 7/7/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

class Person: NSObject {
  var mutualFriends: Int?
  var image: UIImage?
  var firstName: String!
  var lastName: String!
  var uploads: [Item]!
  var favorites: [Item]!
  var reviews: [Review]!
  var completedExchanges: [Exchange]!
  var id: String! //facebook ID
  var recordID: CKRecordID!
  var formattedName: String {
    return firstName + " " + lastName
  }
  
  init(mutualFriends: Int = 0,
    image: UIImage? = nil,
    firstName: String = "",
    lastName: String = "",
    uploads: [Item] = [],
    favorites: [Item] = [],
    reviews: [Review] = [],
    completedExchanges: [Exchange] = [],
    id: String = "") {
      self.mutualFriends = mutualFriends
      self.image = image
      self.firstName = firstName
      self.lastName = lastName
      self.uploads = uploads
      self.favorites = favorites
      self.reviews = reviews
      self.completedExchanges = completedExchanges
      self.id = id
      super.init()
  }
  
  init(record: CKRecord, database: CKDatabase? = nil) {
    assert(record.recordType == RecordTypes.User, "Trying to create a person from a non User record")
    if let imageAsset = record.objectForKey("Image") as? CKAsset {
      image = UIImage(data: NSData(contentsOfURL: imageAsset.fileURL)!)
    }
    firstName = record.objectForKey("FirstName") as! String
    lastName = record.objectForKey("LastName") as! String
    id = record.objectForKey("FacebookID") as! String
    recordID = record.recordID
    super.init()
  }
  func updatePersonWithRecord(record: CKRecord) {
    assert(record.recordType == RecordTypes.User, "Trying to create a person from a non User record")
    if let imageAsset = record.objectForKey("Image") as? CKAsset {
      image = UIImage(data: NSData(contentsOfURL: imageAsset.fileURL)!)
    }
    firstName = record.objectForKey("FirstName") as? String ?? firstName
    lastName = record.objectForKey("LastName") as? String ?? lastName
    id = record.objectForKey("FacebookID") as? String ?? id
    recordID = record.recordID ?? recordID
  }
}
