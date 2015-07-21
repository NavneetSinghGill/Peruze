//
//  ProfileReviewsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileReviewsDataSource: NSObject, UITableViewDataSource {
    struct Constants {
        static let ReuseIdentifier = "ProfileReview"
        static let WriteReviewReuse = "WriteReview"
        static let NibName = "ProfileReviewsTableViewCell"
    }
    var writeReviewEnabled = false
    var reviews = [Review]()
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
        if writeReviewEnabled && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.WriteReviewReuse, forIndexPath: indexPath) as UITableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
            forIndexPath: indexPath) as! ProfileReviewsTableViewCell
            //TODO: Edit the cell contents
            cell.titleLabel.text = "\(indexPath.row + 1). \(reviews[indexPath.row].title)"
            cell.starView.numberOfStars = reviews[indexPath.row].starRating?.floatValue ?? 0
            cell.subtitleLabel.text = "\(reviews[indexPath.row].reviewer!.formattedName) - October 31, 2014"
            cell.review.text = "\(reviews[indexPath.row].description)"
            return cell
        }
       
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return writeReviewEnabled ? (section == 0 ? 1 : reviews.count) : reviews.count
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return writeReviewEnabled ? 2 : 1
    }
}
