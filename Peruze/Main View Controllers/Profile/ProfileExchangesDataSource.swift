//
//  ProfileExchangesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileExchangesDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    static let ReuseIdentifier = "ProfileExchange"
    static let NibName = "ProfileExchangesTableViewCell"
    static let EmptyReuseIdentifier = "EmptyCell"
  }
  var tableView: UITableView!
  var fetchedResultsController: NSFetchedResultsController!
  
  override init() {
    super.init()
//    let predicate = NSPredicate(value: true)
    let predicate = NSPredicate(format: "status == %@", NSNumber(integer: ExchangeStatus.Completed.rawValue))
    let itemsTitleAndImageNotNil = NSPredicate(format: "itemOffered.title != nil AND itemRequested.title != nil AND itemOffered.image != nil AND itemRequested.image != nil")
    fetchedResultsController = Exchange.MR_fetchAllSortedBy(
      "date",
      ascending: true,
      withPredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, itemsTitleAndImageNotNil]),
      groupBy: nil,
      delegate: self,
      inContext: managedConcurrentObjectContext
    )
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    let emptyNib = UINib(nibName: Constants.EmptyReuseIdentifier, bundle: NSBundle.mainBundle())
    
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    tableView.registerNib(emptyNib, forCellReuseIdentifier: Constants.EmptyReuseIdentifier)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
      forIndexPath: indexPath) as! ProfileExchangesTableViewCell
    
    let exchange: AnyObject = fetchedResultsController.objectAtIndexPath(indexPath)
    
    //check for all the data needed to populate the cell
    
    // Swift 2.0
    guard
      let itemOffered = exchange.valueForKey("itemOffered") as? NSManagedObject,
      let itemRequested = exchange.valueForKey("itemRequested") as? NSManagedObject
      else {
        logw("could not get item Offered or item Requested")
        return cell
    }
    guard
      let itemOfferedTitle = itemOffered.valueForKey("title") as? String,
      let itemRequestedTitle = itemRequested.valueForKey("title") as? String
      else {
        logw("could not get itemOfferedTitle or itemRequestedTitle")
        return cell
    }
    guard
      let itemOfferedImage = itemOffered.valueForKey("image") as? NSData,
      let itemRequestedImage = itemRequested.valueForKey("image") as? NSData
      else {
        logw("could not get itemOfferedImage or itemRequestedImage")
        return cell
    }
    guard
      let itemOfferedOwner = itemOffered.valueForKey("owner") as? NSManagedObject,
      let itemOfferedOwnerImage = itemOfferedOwner.valueForKey("image") as? NSData,
      let itemOfferedOwnerName = itemOfferedOwner.valueForKey("firstName") as? String
      else {
        logw("There was not enough data for this exchange to populate the table")
        return tableView.dequeueReusableCellWithIdentifier(Constants.EmptyReuseIdentifier)!
    }
    
    guard
        let itemRequestedOwner = itemRequested.valueForKey("owner") as? NSManagedObject,
        let itemRequestedOwnerImage = itemRequestedOwner.valueForKey("image") as? NSData,
        let itemRequestedOwnerName = itemRequestedOwner.valueForKey("firstName") as? String
        else {
            logw("There was not enough data for this exchange to populate the table")
            return tableView.dequeueReusableCellWithIdentifier(Constants.EmptyReuseIdentifier)!
    }
    
    //set the values from above
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    if me.valueForKey("recordIDName") as! String != itemOfferedOwner.valueForKey("recordIDName") as! String {
        cell.profileImageView.image = UIImage(data: itemOfferedOwnerImage)
        cell.nameLabel.text = "\(itemOfferedOwnerName)'s"
        cell.itemLabel.text = itemOfferedTitle
        cell.itemSubtitle.text = "for your \(itemRequestedTitle)"
        cell.itemsExchangedImage.itemImages = (UIImage(data: itemOfferedImage)!, UIImage(data: itemRequestedImage)!)
    } else {
        cell.profileImageView.image = UIImage(data: itemRequestedOwnerImage)
        cell.nameLabel.text = "\(itemRequestedOwnerName)'s"
        cell.itemLabel.text = itemRequestedTitle
        cell.itemSubtitle.text = "for your \(itemOfferedTitle)"
        cell.itemsExchangedImage.itemImages = (UIImage(data: itemRequestedImage)!, UIImage(data: itemOfferedImage)!)
    }
    
    //set the date
    if let requestDate = exchange.valueForKey("date") as? NSDate {
      let dateString = NSDateFormatter.localizedStringFromDate(requestDate, dateStyle: .LongStyle, timeStyle: .NoStyle)
      cell.dateLabel.text = dateString
    } else {
      cell.dateLabel.text = " "
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
  }
  
  //MARK: - NSFetchedResultsControllerDelegate
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView.beginUpdates()
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    case .Delete:
      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    default:
      break
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Delete:
      tableView.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Update:
      tableView.reloadRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    }
    
  }
  
  // Swift 2.0
  //  func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
  //    switch type {
  //    case .Insert:
  //      tableView.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Delete:
  //      tableView.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Update:
  //      tableView.reloadRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Move:
  //      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    }
  //  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    dispatch_async(dispatch_get_main_queue()) {
        self.tableView.endUpdates()
    }
  }
  
  
  
}
