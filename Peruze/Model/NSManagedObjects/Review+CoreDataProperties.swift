//
//  Review+CoreDataProperties.swift
//  Peruze
//
//  Created by Phillip Trent on 7/20/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Review {

    @NSManaged var detail: String?
    @NSManaged var recordIDName: String?
    @NSManaged var starRating: NSNumber?
    @NSManaged var title: String?
    @NSManaged var userBeingReviewed: Person?
    @NSManaged var reviewer: Person?

}
