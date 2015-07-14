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
    
    override init() {
        super.init()
    }
    convenience init(status: ExchangeStatus, itemRequested: Item, itemOffered: Item, dateExchanged: NSDate?) {
        self.init()
        self.status = status
        self.itemRequested = itemRequested
        self.itemOffered = itemOffered
        self.dateExchanged = dateExchanged
    }
    convenience init(record: CKRecord, database: CKDatabase) {
        
        self.init()
    }
}
