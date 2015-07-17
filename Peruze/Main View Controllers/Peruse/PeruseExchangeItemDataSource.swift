//
//  PeruseExchangeItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/9/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class PeruseExchangeItemDataSource: NSObject, UICollectionViewDataSource {
  
  
  private struct Constants {
    static let ReuseIdentifier = "ExchangeItem"
    static let NibName = "PeruseExchangeItemCollectionViewCell"
  }
  var collectionView:UICollectionView? {
    didSet {
      collectionView!.dataSource = self
      collectionView!.reloadData()
      let nib = UINib(nibName: Constants.NibName, bundle: nil)
      collectionView!.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    }
  }
  var exchangeItems = Model.sharedInstance().myProfile?.uploads ?? [Item]() {
    didSet {
      collectionView?.reloadData()
    }
  }

  func deleteItemsAtIndexPaths(paths: [NSIndexPath]) -> [Item] {
    var returnValue = [Item]()
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
  func addItemsAtIndexPaths(items: [Item], paths: [NSIndexPath]) {
    var itemIterator = 0
    for singlePath in paths {
      exchangeItems.insert(items[itemIterator], atIndex: singlePath.item)
      ++itemIterator
    }
  }
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: nil)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    var cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseExchangeItemCollectionViewCell
    if indexPath.item < exchangeItems.count {
      cell.itemNameLabel.text = exchangeItems[indexPath.item].title
      cell.imageView.image = exchangeItems[indexPath.item].image
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
