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
    let itemsTitleAndImageNotNil = NSPredicate(format: "itemOffered.title != nil AND itemRequested.title != nil AND itemOffered.imageUrl != nil AND itemRequested.imageUrl != nil")
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
      let itemOfferedImageUrl = itemOffered.valueForKey("imageUrl") as? String,
      let itemRequestedImageUrl = itemRequested.valueForKey("imageUrl") as? String
      else {
        logw("could not get itemOfferedImage or itemRequestedImage")
        return cell
    }
    guard
      let itemOfferedOwner = itemOffered.valueForKey("owner") as? NSManagedObject,
      let itemOfferedOwnerImageUrl = itemOfferedOwner.valueForKey("imageUrl") as? String,
      let itemOfferedOwnerName = itemOfferedOwner.valueForKey("firstName") as? String
      else {
        logw("There was not enough data for this exchange to populate the table")
        return tableView.dequeueReusableCellWithIdentifier(Constants.EmptyReuseIdentifier)!
    }
    
    guard
        let itemRequestedOwner = itemRequested.valueForKey("owner") as? NSManagedObject,
        let itemRequestedOwnerImageUrl = itemRequestedOwner.valueForKey("imageUrl") as? String,
        let itemRequestedOwnerName = itemRequestedOwner.valueForKey("firstName") as? String
        else {
            logw("There was not enough data for this exchange to populate the table")
            return tableView.dequeueReusableCellWithIdentifier(Constants.EmptyReuseIdentifier)!
    }
    
    //set the values from above
    let tempImageView1 = UIImageView()
    let tempImageView2 = UIImageView()
    let tempImageView3 = UIImageView()
    let tempImageView4 = UIImageView()
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    
    if me.valueForKey("recordIDName") as! String != itemOfferedOwner.valueForKey("recordIDName") as! String {
//        cell.profileImageView.image = UIImage(data: itemOfferedOwnerImage)
        tempImageView3.sd_setImageWithURL(NSURL(string: s3Url(itemOfferedOwnerImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            cell.profileImageView.image = image
            cell.contentView.setNeedsDisplay()
        })
        cell.nameLabel.text = "\(itemOfferedOwnerName)'s"
        cell.itemLabel.text = itemOfferedTitle
        cell.itemSubtitle.text = "for your \(itemRequestedTitle)"
        
//        cell.itemsExchangedImage.itemImages = (UIImage(data: itemOfferedImage)!, UIImage(data: itemRequestedImage)!)
        tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(itemOfferedImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            if tempImageView1.image != nil && tempImageView2.image != nil {
                cell.itemsExchangedImage.itemImages = (tempImageView1.image!, tempImageView2.image!)
                cell.contentView.setNeedsDisplay()
            }
        })
        tempImageView2.sd_setImageWithURL(NSURL(string: s3Url(itemRequestedImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            if tempImageView1.image != nil && tempImageView2.image != nil {
                cell.itemsExchangedImage.itemImages = (tempImageView1.image!, tempImageView2.image!)
                cell.contentView.setNeedsDisplay()
            }
        })
    } else {
//        cell.profileImageView.image = UIImage(data: itemRequestedOwnerImage)
        tempImageView4.sd_setImageWithURL(NSURL(string: s3Url(itemRequestedOwnerImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            cell.profileImageView.image = image
            cell.contentView.setNeedsDisplay()
        })
        cell.nameLabel.text = "\(itemRequestedOwnerName)'s"
        cell.itemLabel.text = itemRequestedTitle
        cell.itemSubtitle.text = "for your \(itemOfferedTitle)"
        
//        cell.itemsExchangedImage.itemImages = (UIImage(data: itemRequestedImage)!, UIImage(data: itemOfferedImage)!)
        tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(itemOfferedImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            if tempImageView1.image != nil && tempImageView2.image != nil {
                cell.itemsExchangedImage.itemImages = (tempImageView2.image!, tempImageView1.image!)
                cell.contentView.setNeedsDisplay()
            }
        })
        tempImageView2.sd_setImageWithURL(NSURL(string: s3Url(itemRequestedImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
            if tempImageView1.image != nil && tempImageView2.image != nil {
                cell.itemsExchangedImage.itemImages = (tempImageView2.image!, tempImageView1.image!)
                cell.contentView.setNeedsDisplay()
            }
        })
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
