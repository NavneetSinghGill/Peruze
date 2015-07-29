//
//  ProfileReviewsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import MagicalRecord

class ProfileReviewsDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  struct Constants {
    static let ReuseIdentifier = "ProfileReview"
    static let WriteReviewReuse = "WriteReview"
    static let NibName = "ProfileReviewsTableViewCell"
  }
  var writeReviewEnabled = false
  var fetchedResultsController: NSFetchedResultsController!
  var tableView: UITableView!
  
  
  override init() {
    super.init()
    let predicate = NSPredicate(value: true)
    fetchedResultsController = Review.MR_fetchAllSortedBy(
      "date",
      ascending: true,
      withPredicate: predicate,
      groupBy: nil,
      delegate: self,
      inContext: managedConcurrentObjectContext
    )
  }
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    if writeReviewEnabled && indexPath.section == 0 {
      let cell = tableView.dequeueReusableCellWithIdentifier(Constants.WriteReviewReuse, forIndexPath: indexPath) as UITableViewCell
      return cell
    } else {
      let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
        forIndexPath: indexPath) as! ProfileReviewsTableViewCell
      
      let review = fetchedResultsController.objectAtIndexPath(indexPath)
      //TODO: Edit the cell contents
      guard
        let title = review.valueForKey("title") as? String,
        let reviewer = review.valueForKey("reviewer") as? NSManagedObject,
        let firstName = reviewer.valueForKey("firstName") as? String,
        let detail = reviewer.valueForKey("detail") as? String,
        let date = review.valueForKey("date") as? NSDate
        else {
          return cell
      }
      cell.titleLabel.text = "\(indexPath.row + 1). \(title)"
      cell.starView.numberOfStars = (review.valueForKey("starRating") as? NSNumber)?.floatValue ?? 0
      let dateString = NSDateFormatter.localizedStringFromDate(date, dateStyle: .LongStyle, timeStyle: .NoStyle)
      cell.subtitleLabel.text = firstName + " - " + dateString
      cell.review.text = detail
      return cell
    }
    
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return writeReviewEnabled ? (section == 0 ? 1 : (fetchedResultsController?.sections?[section].numberOfObjects ?? 0)) : (fetchedResultsController?.sections?[section].numberOfObjects ?? 0)
  }
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return writeReviewEnabled ? 2 : 1
  }
}
