//
//  Message+CoreDataProperties.swift
//  Peruze
//
//  Created by Phillip Trent on 7/26/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
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
    @NSManaged var exchange: Exchange?
    @NSManaged var sender: Person?

}
