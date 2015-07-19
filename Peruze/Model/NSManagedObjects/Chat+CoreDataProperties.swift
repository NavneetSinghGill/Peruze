//
//  Chat+CoreDataProperties.swift
//  Peruze
//
//  Created by Phillip Trent on 7/18/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
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
