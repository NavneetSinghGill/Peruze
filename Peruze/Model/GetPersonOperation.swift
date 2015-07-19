//
//  GetPersonOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class GetPersonOperation: Operation {
  let personID: CKRecordID
  init(recordID: CKRecordID, context: NSManagedObjectContext) {
    personID = recordID
    super.init()
  }
  init(itemIDName: String, context: NSManagedObjectContext) {
    let item = Item.findFirstByAttribute("recordIDName", withValue: itemIDName)
    guard personID = CKRecordID(recordName: (item.owner?.recordIDName)!) else {
      
    }
    super.init()
  }
  override func execute() {
    
  }
}