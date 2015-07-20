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
  var fetchedResultsController: NSFetchedResultsController!
  var requestDelegate: RequestCollectionViewCellDelegate?
  
  override init() {
    super.init()
    let requestPredicate = NSPredicate(format: "itemRequested.owner.recordIDName == %@", Model.sharedInstance().myProfile.recordIDName!)
    let statusPredicate = NSPredicate(format: "status == %i", ExchangeStatus.Pending.rawValue)
    let fetchedResultsPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([requestPredicate, statusPredicate])
    fetchedResultsController = Exchange.fetchAllSortedBy("date",
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
    
    if let exchange = fetchedResultsController.objectAtIndexPath(indexPath) as? Exchange {
      let myItem = exchange.itemRequested!
      let theirItem = exchange.itemOffered!
      cell.profileImageView.image = UIImage(data: theirItem.owner!.image!)
      cell.nameLabel.text = "\(theirItem.owner!.firstName)'s"
      cell.itemLabel.text = "\(theirItem.title)"
      cell.itemSubtitle.text = "for your \(myItem.title)"
      if let requestDate = exchange.date {
        let dateString = NSDateFormatter.localizedStringFromDate(requestDate, dateStyle: .LongStyle, timeStyle: .NoStyle)
        cell.dateLabel.text = dateString
      } else {
        cell.dateLabel.text = ""
      }
      cell.itemsExchangedImage.itemImages = (UIImage(data: theirItem.image!)!, UIImage(data: myItem.image!)!)
      cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
    return cell
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) { /* keep this empty */ }
  
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
    return retIndexPath
  }
}
