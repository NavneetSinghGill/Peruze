//
//  Chat+CoreDataProperties.swift
//  
//
//  Created by Phillip Trent on 7/20/15.
//
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Chat {

    @NSManaged var recordIDName: String?
    @NSManaged var exchange: Exchange?
    @NSManaged var messages: NSSet?

}
