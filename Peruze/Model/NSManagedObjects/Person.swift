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
    if let firstName = firstName,let lastName = lastName {
    return firstName + " " + lastName
    } else {
      return ""
    }
  }
}
