//
//  ProfileFavoritesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

extension ProfileFavoritesDataSource: InfiniteCollectionViewDataSource {
    func numberOfItems(collectionView: UICollectionView) -> Int
    {
        var returnValue = 0
        if favorites.count == 0 {
            returnValue = 1
        } else {
            returnValue = favorites.count
        }
        return returnValue
    }
    
    func cellForItemAtIndexPath(collectionView: UICollectionView, dequeueIndexPath: NSIndexPath, usableIndexPath: NSIndexPath)  -> UICollectionViewCell
    {
        let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifiers.CollectionViewCell)
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifiers.CollectionViewCell, forIndexPath: dequeueIndexPath) as! PeruseItemCollectionViewCell)
        
        cell.item = favorites[dequeueIndexPath.row % favorites.count]
        cell.delegate = itemDelegate
        cell.itemFavorited = true
        cell.setNeedsDisplay()
        return cell
    }
}

class ProfileFavoritesDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIScrollViewDelegate {
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
    var tableView: UITableView!
    var tempImageView = UIImageView()
    override init() {
        super.init()
        refresh()
    }
    
  ///fetch current user profile and set `favorites` to the favorites of my profile
  func refresh() -> Int {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    if let favorites = me.valueForKey("favorites") as? NSSet {
      if let favoriteObjs = favorites.allObjects as? [NSManagedObject] {
        self.favorites = []
        for favoriteObj in favoriteObjs{
            if favoriteObj.valueForKey("hasRequested") != nil && favoriteObj.valueForKey("title") != nil && favoriteObj.valueForKey("hasRequested") as! String == "no"  {
                self.favorites.append(favoriteObj)
            }
        }
      } else {
        logw("me.valueForKey('favorites').allObjects was not an [NSManagedObject] ")
      }
    } else {
      logw("me.valueForKey('favorites') was not an NSSet ")
    }
    dispatch_async(dispatch_get_main_queue()){
        if self.tableView != nil {
            self.tableView.reloadData()
            //NSUserDefaults.standardUserDefaults().valueForKey("FavouriteIndex")
        }
    }
    return self.favorites.count
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
        let detail = item.valueForKey("detail") as? String
//        let imageData = item.valueForKey("image") as? NSData
      {
        cell.titleTextLabel.text = title
        cell.subtitleTextLabel.text = "by \(ownerName)"
        cell.descriptionTextLabel.text = detail
//        if let imageData = item.valueForKey("image") as? NSData{
//            cell.circleImageView.image = UIImage(data: imageData)
//        } else {
//            cell.circleImageView.image = nil
//        }
        
//        if let imageUrl = item.valueForKey("imageUrl") as? String {
//            tempImageView = UIImageView()
//            weak var weakCell = cell
//            tempImageView.sd_setImageWithURL(NSURL(string: s3Url(imageUrl)), completed: {
//                (image, error, sdImageCacheType, url) -> Void in
//                weakCell!.circleImageView.image = nil
//                weakCell!.circleImageView.image = image
//                weakCell!.setNeedsDisplay()
//            })
//            cell.circleImageView.image = tempImageView.image
//        }
        if let imageUrl = item.valueForKey("imageUrl") as? String {
            cell.circleButton.sd_setImageWithURL(NSURL(string: s3Url(imageUrl)), forState: UIControlState.Normal)
        }
        cell.circleButton.layer.cornerRadius = cell.circleButton.frame.size.width / 2
        cell.circleButton.layer.masksToBounds = true
        
      } else {
        logw("There was not enough non-nil data for the favorite item")
      }
    } else {
      logw("There is no cell for NSIndexPath: \(indexPath)")
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
    let cell = (collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifiers.CollectionViewCell, forIndexPath: indexPath) as! PeruseItemCollectionViewCell)
    
//    if cell == nil {
//        cell = PeruseItemCollectionViewCell()
//    }
    let item = favorites[indexPath.row]
    
    cell.item = favorites[indexPath.row]
    cell.delegate = itemDelegate
    //      let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
    cell.itemFavorited = true
    cell.setNeedsDisplay()
    return cell
  }
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return favorites.count
  }
  
  
}
