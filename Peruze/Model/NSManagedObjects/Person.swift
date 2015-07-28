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
  var formattedName: String {
    if let firstName = self.valueForKey("firstName") as? String,
      let lastName = self.valueForKey("lastName") as? String {
    return firstName + " " + lastName
    } else {
      return ""
    }
  }
}
