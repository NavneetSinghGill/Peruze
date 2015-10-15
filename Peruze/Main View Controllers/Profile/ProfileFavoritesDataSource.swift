//
//  ProfileFavoritesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileFavoritesDataSource: NSObject, UITableViewDataSource, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    static let NibName = "ProfileUploadsTableViewCell"
    struct ReuseIdentifiers {
      static let TableViewCell = "ProfileUpload"
      static let CollectionViewCell = "item"
    }
  }
  ///current user's favorite objects, which should be of `Item` class
  var favorites = [NSManagedObject]()
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var editableCells = true
  
  ///fetch current user profile and set `favorites` to the favorites of my profile
  func refresh() {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    if let favorites = me.valueForKey("favorites") as? NSSet {
      if let favoriteObjs = favorites.allObjects as? [NSManagedObject] {
        self.favorites = favoriteObjs
      } else {
        print("me.valueForKey('favorites').allObjects was not an [NSManagedObject] ")
      }
    } else {
      print("me.valueForKey('favorites') was not an NSSet ")
    }
  }
  //MARK: - UITableViewDataSource methods
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifiers.TableViewCell)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifiers.TableViewCell,
      forIndexPath: indexPath) as! ProfileUploadsTableViewCell
    if favorites.count > indexPath.row {
      let item = favorites[indexPath.row]
      if
        let title = item.valueForKey("title") as? String,
        let owner = item.valueForKey("owner") as? NSManagedObject,
        let ownerName = owner.valueForKey("firstName") as? String,
        let detail = item.valueForKey("detail") as? String,
        let imageData = item.valueForKey("image") as? NSData
      {
        cell.titleTextLabel.text = title
        cell.subtitleTextLabel.text = "by \(ownerName)"
        cell.descriptionTextLabel.text = detail
        cell.circleImageView.image = UIImage(data: imageData)
      } else {
        print("There was not enough non-nil data for the favorite item")
      }
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
    
    cell.item = item
    cell.delegate = itemDelegate
    cell.setNeedsDisplay()
    return cell
  }
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return favorites.count
  }
  
  
}
