//
//  PostReviewOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 8/25/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit

class PostReviewOperation: Operation {
  
  let presentationContext: UIViewController
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(presentationContext: UIViewController,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase) {
      self.presentationContext = presentationContext
      self.context = context
      self.database = database
      super.init()
  }
  
  override func execute() {
    //do shit
  }
  
  override func finished(errors: [ErrorType]) {
    if errors.first != nil {
      let alert = AlertOperation(presentFromController: presentationContext)
      alert.message = ""
      alert.title = ""
    }
  }
  
}