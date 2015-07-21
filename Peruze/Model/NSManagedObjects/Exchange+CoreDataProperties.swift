//
//  Exchange+CoreDataProperties.swift
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

extension Exchange {

    @NSManaged var date: NSDate?
    @NSManaged var recordIDName: String?
    @NSManaged var status: NSNumber?
    @NSManaged var creator: Person?
    @NSManaged var itemOffered: Item?
    @NSManaged var itemRequested: Item?
    @NSManaged var chat: Chat?

}
