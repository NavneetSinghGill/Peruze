//
//  Review.swift
//  Peruse
//
//  Created by Phillip Trent on 7/7/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

class Review: NSObject {
    var starRatingValue: Float = 0
    var reviewer: Person!
    var date: NSDate!
    var title: String!
    var personBeingReviewed: Person!
    override init() {
        super.init()
    }
    convenience init(record: CKRecord, database: CKDatabase) {
        self.init()
    }
}
