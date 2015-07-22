//
//  ProfileFavoritesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import MagicalRecord

class ProfileFavoritesDataSource: NSObject, UITableViewDataSource, UICollectionViewDataSource {
  private struct Constants {
    static let NibName = "ProfileUploadsTableViewCell"
    struct ReuseIdentifiers {
      static let TableViewCell = "ProfileUpload"
      static let CollectionViewCell = "item"
    }
  }
  var favorites = [Item]()
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var editableCells = true
  //MARK: - UITableViewDataSource methods
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifiers.TableViewCell)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifiers.TableViewCell,
      forIndexPath: indexPath) as! ProfileUploadsTableViewCell
    if favorites.count > indexPath.row {
      cell.titleTextLabel.text = favorites[indexPath.row].title
      cell.subtitleTextLabel.text = "by \(favorites[indexPath.row].owner!.firstName)"
      cell.descriptionTextLabel.text = favorites[indexPath.row].description
      cell.circleImageView.image = UIImage(data: favorites[indexPath.row].image!)
    } else {
      print("There is no cell for NSIndexPath: \(indexPath)")
    }
    return cell
  }
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return favorites.count
  }
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return editableCells
  }
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  //MARK: - UICollectionViewDataSource methods
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifiers.CollectionViewCell)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifiers.CollectionViewCell, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
    
    let item = NSManagedObject()
    guard
      //let item = fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject,
      let itemImageData = item.valueForKey("image") as? NSData,
      let itemTitle = item.valueForKey("title") as? String,
      let itemDetail = item.valueForKey("detail") as? String//,
      //      let itemOwner = item.valueForKey("owner") as? NSManagedObject,
      //      let ownerFirstName = item.valueForKey("firstName") as? String,
      //      let ownerLastName = item.valueForKey("lastName") as? String,
      //      let ownerImageData = item.valueForKey("image") as? NSData
      else {
        return UICollectionViewCell()
    }
    let localOwner = OwnerStruct(
      image: UIImage(data: itemImageData)!,
      formattedName: "",
      recordIDName: ""
    )
    let localItem = ItemStruct(
      image: UIImage(data: itemImageData)!,
      title: itemTitle,
      detail: itemDetail,
      owner: localOwner,
      recordIDName: ""
    )
    
    cell.item = localItem
    cell.delegate = itemDelegate
    cell.setNeedsDisplay()
    return cell
  }
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return favorites.count
  }
  
  
}
