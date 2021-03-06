//
//  RequestsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/15/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CoreData
import SwiftLog

class RequestsDataSource: NSObject, UICollectionViewDataSource, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    static let CollectionViewNibName = "RequestsCollectionViewCell"
    static let CollectionViewReuseIdentifier = "request"
    static let TableViewNibName = "ProfileExchangesTableViewCell"
    static let TableViewReuseIdentifier = "ProfileExchange"
  }
  var tableView: UITableView!
  var fetchedResultsController: NSFetchedResultsController!
  var requestDelegate: RequestCollectionViewCellDelegate?
  
  override init() {
    super.init()
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    //POPUP iCloud
    let myRecordID = myPerson.valueForKey("recordIDName") as! String
    
    let statusPredicate = NSPredicate(format: "status == %@", NSNumber(integer: ExchangeStatus.Pending.rawValue))
    let myRequestedPredicate = NSPredicate(format: "itemRequested.owner.recordIDName == %@", myRecordID)
    let itemsTitleNotNil = NSPredicate(format: "itemOffered.title != nil AND itemRequested.title != nil")
//    let requestedItemTitleNotNil = NSPredicate(format: "itemRequested.title != nil")
    let fetchedResultsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, myRequestedPredicate, itemsTitleNotNil])
    fetchedResultsController = Exchange.MR_fetchAllSortedBy("date",
      ascending: true,
      withPredicate: fetchedResultsPredicate,
      groupBy: nil,
      delegate: self)
    do {
        try self.fetchedResultsController.performFetch()
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) number of requests: \(self.fetchedResultsController.sections?[0].numberOfObjects)")
    } catch {
      logw("RequestsDataSource fetchResult failed with error: \(error)")
    }
  }
  
  //MARK: - UICollectionView Data Source
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: Constants.CollectionViewNibName, bundle: nil)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.CollectionViewReuseIdentifier)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionViewReuseIdentifier, forIndexPath: indexPath) as! RequestsCollectionViewCell
    cell.delegate = requestDelegate
    if let exchange = fetchedResultsController.objectAtIndexPath(indexPath) as? Exchange {
      cell.exchange = exchange
      logw("\nRequested exchange table cell data at .... IndexPath:\(indexPath) .... with data: \(exchange)")
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  //MARK: - UITableView Data Source
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.TableViewNibName, bundle: nil)
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.TableViewReuseIdentifier)
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewReuseIdentifier, forIndexPath: indexPath) as! ProfileExchangesTableViewCell
    
    //get exchange
    let exchange = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
    guard
      let myItem = exchange.valueForKey("itemRequested") as? NSManagedObject,
      let myItemTitle = myItem.valueForKey("title") as? String,
      let theirItem = exchange.valueForKey("itemOffered") as? NSManagedObject,
      let theirItemTitle = theirItem.valueForKey("title") as? String,
      let theirOwner = theirItem.valueForKey("owner") as? NSManagedObject,
      let theirProfileImageUrl = theirOwner.valueForKey("imageUrl") as? String,
      let theirOwnerFirstName = theirOwner.valueForKey("firstName") as? String,
      let theirItemImageUrl = theirItem.valueForKey("imageUrl") as? String,
      let myItemImageUrl = myItem.valueForKey("imageUrl") as? String else {
        logw("Requests datasource failure.")
        return cell
    }
    
    cell.itemSubtitle.text = "for your \(myItemTitle)"
    cell.itemLabel.text = theirItemTitle
//    cell.profileImageView.image = UIImage(data: theirProfileImageData)
    
    let tempImageView3 = UIImageView()
    tempImageView3.sd_setImageWithURL(NSURL(string: s3Url(theirProfileImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
        if tempImageView3.image != nil {
            cell.profileImageView.image = image
            cell.contentView.setNeedsDisplay()
        }
    })
    cell.nameLabel.text = "\(theirOwnerFirstName)'s"
    
    let tempImageView1 = UIImageView()
    let tempImageView2 = UIImageView()
    tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(theirItemImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
        if tempImageView1.image != nil && tempImageView2.image != nil {
            cell.itemsExchangedImage.itemImages = (tempImageView1.image!, tempImageView2.image!)
            cell.contentView.setNeedsDisplay()
        }
    })
    tempImageView2.sd_setImageWithURL(NSURL(string: s3Url(myItemImageUrl)), completed: { (image, error, sdImageCacheType, url) -> Void in
        if tempImageView1.image != nil && tempImageView2.image != nil {
            cell.itemsExchangedImage.itemImages = (tempImageView1.image!, tempImageView2.image!)
            cell.contentView.setNeedsDisplay()
        }
    })
    if let requestDate = exchange.valueForKey("date") as? NSDate {
      let dateString = NSDateFormatter.localizedStringFromDate(requestDate, dateStyle: .LongStyle, timeStyle: .NoStyle)
      cell.dateLabel.text = dateString
    } else {
      cell.dateLabel.text = " "
    }
    
    //cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    
    return cell
  }
  
  private func errorCell() -> ProfileExchangesTableViewCell {
    let returnCell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewReuseIdentifier) as! ProfileExchangesTableViewCell
    returnCell.nameLabel.text = "Error"
    returnCell.itemLabel.text = "Please refresh"
    return returnCell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    /* keep this empty */
  }
  
  //MARK: - NSFetchedResultsControllerDelegate
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView?.beginUpdates()
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      tableView?.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    case .Delete:
      tableView?.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    default:
      break
    }
  }
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView?.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Delete:
      tableView?.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Update:
      tableView?.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView?.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Move:
      tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    tableView?.endUpdates()
  }
  
  //MARK: - Editing Data
  func deleteItemAtIndex(index: Int) -> Exchange {
    let retValue = fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as! NSManagedObject
    retValue.setValue(NSNumber(integer: ExchangeStatus.Denied.rawValue), forKey: "status")
    let exchangeVal = retValue as! Exchange
    return exchangeVal
  }
  
    func deleteRequest(requestToDelete: Exchange) -> NSIndexPath {
        let retIndexPath = fetchedResultsController.indexPathForObject(requestToDelete)
        let retValue = fetchedResultsController.objectAtIndexPath(retIndexPath!) as! NSManagedObject
        retValue.setValue(NSNumber(integer: ExchangeStatus.Denied.rawValue), forKey: "status")
        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        //    do {
        //        try self.fetchedResultsController.performFetch()
        //    }
        //    catch {
        //        
        //    }
        return retIndexPath!
    }
    
    func acceptRequest(requestToDelete: Exchange) -> NSIndexPath {
        let retIndexPath = fetchedResultsController.indexPathForObject(requestToDelete)
        let retValue = fetchedResultsController.objectAtIndexPath(retIndexPath!) as! NSManagedObject
        retValue.setValue(NSNumber(integer: ExchangeStatus.Accepted.rawValue), forKey: "status")
        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        //    do {
        //        try self.fetchedResultsController.performFetch()
        //    }
        //    catch {
        //        
        //    }
        return retIndexPath!
    }
}
