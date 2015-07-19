//
//  Item.swift
//  Peruse
//
//  Created by Phillip Trent on 7/7/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

class Item: NSObject {
  var image: UIImage!
  var owner: Person!
  var title: String!
  var detail: String!
  var id: CKRecordID!
  override init() {
    super.init()
  }
  convenience init(image: UIImage, owner: Person, title: String, detail: String, id: CKRecordID) {
    self.init()
    self.image = image
    self.owner = owner
    self.title = title
    self.detail = detail
    self.id = id
  }
  convenience init(record: CKRecord, database: CKDatabase) {
    self.init()
    detail = record.objectForKey("Description") as? String ?? ""
    let asset = record.objectForKey("Image") as? CKAsset
    let fileURLPath = asset?.fileURL.path ?? ""
    image = UIImage(contentsOfFile: fileURLPath) ?? UIImage()
    title = record.objectForKey("Title") as? String ?? ""
    id = record.recordID
    let ownerRef = record.objectForKey("Owner") as? CKReference
    owner = Person()
    owner.recordID = ownerRef?.recordID
  }
}
