//
//  Message+CoreDataProperties.swift
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

extension Message {

    @NSManaged var image: NSData?
    @NSManaged var recordIDName: String?
    @NSManaged var text: String?
    @NSManaged var chat: Chat?

}
