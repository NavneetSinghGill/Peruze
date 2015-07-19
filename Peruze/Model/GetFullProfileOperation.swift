//
//  GetFullProfileOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
///A group operation to fetch all aspects of a user's profile
class GetFullProfileOperation: GroupOperation {
  let fetchPersonOperation: GetPersonOperation
  let fetchReviewsOperation: GetReviewsOperation
  let fetchUploadsOperation: GetUploadsOperation
}