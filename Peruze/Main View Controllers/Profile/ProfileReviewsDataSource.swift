//
//  ProfileReviewsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileReviewsDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  struct Constants {
    static let ReuseIdentifier = "ProfileReview"
    static let WriteReviewReuse = "WriteReview"
    static let NibName = "ProfileReviewsTableViewCell"
  }
  var writeReviewEnabled = false
  var fetchedResultsController: NSFetchedResultsController!
  var tableView: UITableView!
  var profileOwner: Person!
  
  
  override init() {
    super.init()
    fetchData()
  }
    
    func fetchData() -> Int{
        let recordIDName: String
        if profileOwner != nil && profileOwner.valueForKey("recordIDName") != nil{
            recordIDName = profileOwner.valueForKey("recordIDName") as! String
        } else {
//            let me = Person.MR_findFirstByAttribute("me", withValue: true)
//            recordIDName = me.valueForKey("recordIDName") as! String
            recordIDName = "__showNothing__"
        }
        let predicate = NSPredicate(format: "userBeingReviewed.recordIDName == %@", recordIDName)
        fetchedResultsController = Review.MR_fetchAllSortedBy(
            "date",
            ascending: true,
            withPredicate: predicate,
            groupBy: nil,
            delegate: self,
            inContext: managedConcurrentObjectContext
        )
        if self.tableView != nil{
            dispatch_async(dispatch_get_main_queue()){
                self.tableView.reloadData()
            }
        }
        return fetchedResultsController.sections![0].numberOfObjects
    }
    
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    if writeReviewEnabled && indexPath.section == 0 {
      let cell = tableView.dequeueReusableCellWithIdentifier(Constants.WriteReviewReuse, forIndexPath: indexPath)
      return cell
    } else {
      let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
        forIndexPath: indexPath) as! ProfileReviewsTableViewCell
      let review: AnyObject = fetchedResultsController.sections![0].objects![indexPath.row]
        
      //TODO: Edit the cell contents
      guard
        let title = review.valueForKey("title") as? String,
        let reviewer = review.valueForKey("reviewer") as? NSManagedObject,
        let firstName = reviewer.valueForKey("firstName") as? String,
        let detail = review.valueForKey("detail") as? String,
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
    return writeReviewEnabled ? (section == 0 ? 1 : (fetchedResultsController?.sections?[0].numberOfObjects ?? 0)) : (fetchedResultsController?.sections?[section].numberOfObjects ?? 0)
  }
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return writeReviewEnabled ? 2 : 1
  }
}
