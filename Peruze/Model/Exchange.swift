//
//  Exchange.swift
//  Peruse
//
//  Created by Phillip Trent on 7/7/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

enum ExchangeStatus: Int {
  case Pending = 0, Accepted, Denied, Completed, Canceled
}

class Exchange: NSObject {
  var status: ExchangeStatus!
  var itemRequested: Item!
  var itemOffered: Item!
  var dateExchanged: NSDate?
  var recordID: CKRecordID?
  
  init(status: ExchangeStatus, itemRequested: Item, itemOffered: Item, dateExchanged: NSDate?) {
    self.status = status
    self.itemRequested = itemRequested
    self.itemOffered = itemOffered
    self.dateExchanged = dateExchanged
    super.init()
  }
  init(record: CKRecord, database: CKDatabase? = nil) {
    status = ExchangeStatus(rawValue: record.objectForKey("ExchangeStatus") as! Int)
    dateExchanged = record.objectForKey("DateExchanged") as? NSDate
    let requestedReference = record.objectForKey("RequestedItem") as? CKReference
    itemRequested = Item()
    itemRequested.id = requestedReference?.recordID
    let offeredReference = record.objectForKey("OfferedItem") as? CKReference
    itemOffered = Item()
    itemOffered.id = offeredReference?.recordID
    recordID = record.recordID
    super.init()
  }
}
