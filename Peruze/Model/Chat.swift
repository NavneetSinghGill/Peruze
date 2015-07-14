//
//  Chat.swift
//  Peruse
//
//  Created by Phillip Trent on 7/7/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit
import JSQMessagesViewController

class Chat: NSObject {
    var exchage: Exchange!
    var messages: [JSQMessage]!
    override init() {
        super.init()
    }
    convenience init(exchange: Exchange, messages: [JSQMessage]) {
        self.init()
        self.exchage = exchange
        self.messages = messages
    }
    convenience init(record: CKRecord, database: CKDatabase) {
        self.init()
    }
}
