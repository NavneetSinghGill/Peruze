//
//  RequestsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/15/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CoreData
import MagicalRecord

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
    let statusPredicate = NSPredicate(format: "status = %@", NSNumber(integer: ExchangeStatus.Pending.rawValue))
    let fetchedResultsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate])
    fetchedResultsController = Exchange.MR_fetchAllSortedBy("date",
      ascending: true,
      withPredicate: fetchedResultsPredicate,
      groupBy: nil,
      delegate: self)
    do {
      try fetchedResultsController.performFetch()
    } catch {
      print(error)
      //TODO: Actually handle this error
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
    let exchange = fetchedResultsController.objectAtIndexPath(indexPath)
    
    //make sure that all the values are present
    guard
      let myItem = exchange.valueForKey("itemRequested") as? NSManagedObject,
      let myItemTitle = myItem.valueForKey("title") as? String,
      let theirItem = exchange.valueForKey("itemOffered") as? NSManagedObject,
      let theirItemTitle = theirItem.valueForKey("title") as? String,
      let theirOwner = theirItem.valueForKey("owner") as? NSManagedObject,
      let theirProfileImageData = theirOwner.valueForKey("image") as? NSData,
      let theirOwnerFirstName = theirOwner.valueForKey("firstName") as? String,
      let theirItemImage = theirItem.valueForKey("image") as? NSData,
      let myItemImage = myItem.valueForKey("image") as? NSData
    //let exchangeStatus = exchange.valueForKey("status") as? NSNumber
      else {
        return errorCell()
    }
    cell.itemSubtitle.text = "for your \(myItemTitle)"
    cell.itemLabel.text = theirItemTitle
    cell.profileImageView.image = UIImage(data: theirProfileImageData)
    cell.nameLabel.text = "\(theirOwnerFirstName)'s"
    cell.itemsExchangedImage.itemImages = (UIImage(data: theirItemImage)!, UIImage(data: myItemImage)!)
    
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
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Update:
      tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    tableView.endUpdates()
  }
  
  //MARK: - Editing Data
  func deleteItemAtIndex(index: Int) -> Exchange {
    guard let retValue = fetchedResultsController.objectAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? Exchange  else {
      assertionFailure("The item returned at the given index was not an exchange")
      abort()
    }
    retValue.status = ExchangeStatus.Denied.rawValue
    return retValue
  }
  
  func deleteRequest(requestToDelete: Exchange) -> NSIndexPath {
    let retIndexPath = fetchedResultsController.indexPathForObject(requestToDelete)
    guard let retValue = fetchedResultsController.objectAtIndexPath(retIndexPath!) as? Exchange  else {
      assertionFailure("The item returned at the given index was not an exchange")
      abort()
    }
    retValue.status = ExchangeStatus.Denied.rawValue
    return retIndexPath!
  }
}
