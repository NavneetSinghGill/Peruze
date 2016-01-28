//
//  PeruseExchangeItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/9/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class PeruseExchangeItemDataSource: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
  
  
  private struct Constants {
    static let ReuseIdentifier = "ExchangeItem"
    static let NibName = "PeruseExchangeItemCollectionViewCell"
  }
  var fetchedResultsController: NSFetchedResultsController!
  var collectionView:UICollectionView? {
    didSet {
      collectionView!.dataSource = self
      let nib = UINib(nibName: Constants.NibName, bundle: nil)
      collectionView!.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    }
  }
  var exchangeItems = [NSManagedObject]()
    var tempImageView = UIImageView()
  override init() {
    super.init()
    getItems()
  }
  
  func deleteItemsAtIndexPaths(paths: [NSIndexPath]) -> [NSManagedObject] {
    var returnValue = [NSManagedObject]()
    for singlePath in paths {
      if singlePath.item < exchangeItems.count {
        returnValue.append(exchangeItems[singlePath.item])
        exchangeItems.removeAtIndex(singlePath.item)
      } else {
        assertionFailure("Trying to delete exchange item that does not exist")
      }
    }
    return returnValue
  }
  
  func addItemsAtIndexPaths(items: [NSManagedObject], paths: [NSIndexPath]) {
    var itemIterator = 0
    for singlePath in paths {
      exchangeItems.insert(items[itemIterator], atIndex: singlePath.item)
      ++itemIterator
    }
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: nil)
    
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseExchangeItemCollectionViewCell
    
    if indexPath.item < exchangeItems.count {
      let item = exchangeItems[indexPath.item]
      
      guard
        let title = item.valueForKey("title") as? String
        else {
          return cell
      }
        
      cell.itemNameLabel.text = title
        if let imageUrl = item.valueForKey("imageUrl") as? String {
//            cell.imageView.image = UIImage(data: imageData)
            cell.imageView.image = nil
            tempImageView = UIImageView()
            tempImageView.sd_setImageWithURL(NSURL(string: s3Url(imageUrl)), completed: { (image, ErrorType, sdImageCacheType, url) -> Void in
                cell.imageView.image = image
                cell.setNeedsDisplay()
            })
            cell.imageView.imageView?.sd_setImageWithURL(NSURL(string: s3Url(imageUrl)))
        } else {
            cell.imageView.image = nil
        }
    } else if indexPath.item == exchangeItems.count {
      //last item
      cell.itemNameLabel.text = "Upload New Item"
      cell.imageView.image = UIImage(named: "Plus_Sign")
    }
    
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return exchangeItems.count + 1
  }
    
    func getItems() {
        let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
        
        guard let personRecordID = myPerson.valueForKey("recordIDName") as? String else {
            return
        }
        let predicate = NSPredicate(format: "owner.recordIDName = %@ AND title != nil AND imageUrl != nil", personRecordID)
        fetchedResultsController = Item.MR_fetchAllSortedBy("title",
            ascending: true,
            withPredicate: predicate,
            groupBy: nil,
            delegate: self,
            inContext: managedConcurrentObjectContext)
        
        do {
            try fetchedResultsController.performFetch()
            guard let objects = fetchedResultsController.fetchedObjects as? [NSManagedObject] else {
                logw("Issue in Peruze Exchange Item Data Source")
                return
            }
            exchangeItems = objects
        } catch {
            logw("\(error)")
        }
    }
}
