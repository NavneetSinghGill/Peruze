//
//  TaggableFriend+CoreDataProperties.swift
//  Peruze
//
//  Created by stplmacmini11 on 16/02/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import Foundation
import CoreData

extension TaggableFriend {
    @NSManaged var recordIDName: String?
    @NSManaged var facebookID: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var imageUrl: String?
}
