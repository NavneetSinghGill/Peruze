//
//  Item+CoreDataProperties.swift
//  Peruze
//
//  Created by Phillip Trent on 7/25/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Item {

    @NSManaged var detail: String?
    @NSManaged var image: NSData?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var ownerFacebookID: String?
    @NSManaged var recordIDName: String?
    @NSManaged var title: String?
    @NSManaged var owner: Person?

}
