//
//  Person+CoreDataProperties.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Person {

    @NSManaged var facebookID: String?
    @NSManaged var firstName: String?
    @NSManaged var image: NSData?
    @NSManaged var lastName: String?
    @NSManaged var recordIDName: String?
    @NSManaged var favorites: NSSet?
    @NSManaged var uploads: NSSet?
    @NSManaged var exchanges: NSSet?
    @NSManaged var reviews: NSSet?

}
