//
//  PostItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import MagicalRecord

class PostItemOperation: Operation {
  
  let database: CKDatabase
  let context: NSManagedObjectContext
  let item: Item
  
  init(database: CKDatabase,context: NSManagedObjectContext = managedConcurrentObjectContext, item: Item) {
    self.database = database
    self.context = context
    self.item = item
    super.init()
  }
  
  override func execute() {
    
  }
}