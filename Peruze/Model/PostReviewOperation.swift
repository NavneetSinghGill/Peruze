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
    title: String,
    review: String,
    starRating: Int,
    context: NSManagedObjectContext = managedConcurrentObjectContext,
    database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase) {
      self.presentationContext = presentationContext
      self.context = context
      self.database = database
      
  }
  
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.message = ""
      alert.title = ""
    }
  }
  
}