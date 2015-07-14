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
    var items = [Item]()
    override init() {
        super.init()
    }
    
    //MARK: - UICollectionView Data Source
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let nib = UINib(nibName: Constants.CollectionViewNibName, bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.CollectionViewReuseIdentifier)
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionViewReuseIdentifier, forIndexPath: indexPath) as! RequestsCollectionViewCell
        cell.delegate = requestDelegate
        cell.itemOfferedToUser = items[indexPath.item]
        cell.itemRequestedFromUser = items[indexPath.item + 1]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count - 1
    }
    
    //MARK: - UITableView Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.TableViewNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.TableViewReuseIdentifier)
        var cell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewReuseIdentifier, forIndexPath: indexPath) as! ProfileExchangesTableViewCell
        //TODO: Format the date label
        let myItem = items[indexPath.row + 1]
        let theirItem = items[indexPath.row]
        cell.profileImageView.image = theirItem.owner.image
        cell.nameLabel.text = "\(theirItem.owner.firstName)'s"
        cell.itemLabel.text = "\(theirItem.title)"
        cell.itemSubtitle.text = "for your \(myItem.title)"
        cell.dateLabel.text = "June 24, 2015"
        cell.itemsExchangedImage.itemImages = (theirItem.image, myItem.image)
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count - 1
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) { /* keep this empty */}

    //MARK: - Editing Data
    func deleteItemAtIndex(index: Int) {
        if items.count > 0{
            items.removeAtIndex(index)
        }
    }
}
