//
//  PeruseExchangeItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/9/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

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
  override init() {
    super.init()
    let myPerson = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    
    //Swift 2.0
    //    guard let personRecordID = myPerson.valueForKey("recordIDName") as? String else {
    //      return
    //    }
    let personRecordID = myPerson.valueForKey("recordIDName") as! String
    let predicate = NSPredicate(format: "owner.recordIDName = %@", personRecordID)
    fetchedResultsController = Item.MR_fetchAllSortedBy("title",
      ascending: true,
      withPredicate: predicate,
      groupBy: nil,
      delegate: self,
      inContext: managedConcurrentObjectContext)
    
    //Swift 2.0
    //do {
    //      try fetchedResultsController.performFetch()
    //      guard let objects = fetchedResultsController.fetchedObjects else {
    //        return
    //      }
    //      exchangeItems = objects
    //    } catch {
    //      print(error)
    //    }
    
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    if error != nil {
      print(error)
    } else {
      exchangeItems = fetchedResultsController.fetchedObjects as! [NSManagedObject]
    }
    
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
      
      //      guard
      //      let title = item.valueForKey("title") as? String,
      //      let imageData = item.valueForKey("image") as? NSData
      //      else {
      //        return cell
      //      }
      
      let title = item.valueForKey("title") as! String
      let imageData = item.valueForKey("image") as! NSData
      cell.itemNameLabel.text = title
      cell.imageView.image = UIImage(data: imageData)
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
}
