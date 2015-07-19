//
//  RequestsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/15/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class RequestsDataSource: NSObject, UICollectionViewDataSource, UITableViewDataSource {
  private struct Constants {
    static let CollectionViewNibName = "RequestsCollectionViewCell"
    static let CollectionViewReuseIdentifier = "request"
    static let TableViewNibName = "ProfileExchangesTableViewCell"
    static let TableViewReuseIdentifier = "ProfileExchange"
  }
  var requestDelegate: RequestCollectionViewCellDelegate?
  var requests = [Exchange]()
  
  //MARK: - UICollectionView Data Source
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: Constants.CollectionViewNibName, bundle: nil)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.CollectionViewReuseIdentifier)
    var cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionViewReuseIdentifier, forIndexPath: indexPath) as! RequestsCollectionViewCell
    cell.delegate = requestDelegate
    cell.exchange = requests[indexPath.row]
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return requests.count
  }
  
  //MARK: - UITableView Data Source
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.TableViewNibName, bundle: nil)
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.TableViewReuseIdentifier)
    var cell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewReuseIdentifier, forIndexPath: indexPath) as! ProfileExchangesTableViewCell
    let myItem = requests[indexPath.row].itemRequested
    let theirItem = requests[indexPath.row].itemOffered
    cell.profileImageView.image = theirItem.owner.image
    cell.nameLabel.text = "\(theirItem.owner.firstName)'s"
    cell.itemLabel.text = "\(theirItem.title)"
    cell.itemSubtitle.text = "for your \(myItem.title)"
    if let requestDate = requests[indexPath.row].dateExchanged {
      let dateString = NSDateFormatter.localizedStringFromDate(requestDate, dateStyle: .LongStyle, timeStyle: .NoStyle)
      cell.dateLabel.text = dateString
    } else {
      cell.dateLabel.text = ""
    }
    cell.itemsExchangedImage.itemImages = (theirItem.image, myItem.image)
    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    return cell
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return requests.count
  }
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) { /* keep this empty */ }
  
  //MARK: - Editing Data
  func deleteItemAtIndex(index: Int) -> Exchange {
    var retValue = Exchange()
    if requests.count > 0 {
      retValue = requests[index]
      requests.removeAtIndex(index)
    }
    return retValue
  }
  func deleteRequest(requestToDelete: Exchange) -> NSIndexPath {
    var returnPath = NSIndexPath(forItem: 0, inSection: 0)
    for i in 0..<requests.count {
      if requests[i].recordID == requestToDelete.recordID {
        requests.removeAtIndex(i)
        return NSIndexPath(forItem: i, inSection: 0)
      }
    }
    assertionFailure("Tried to delete a request that was not in the requests")
    return NSIndexPath()
  }
}
