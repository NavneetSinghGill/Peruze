//
//  PeruseItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/2/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class PeruseItemDataSource: NSObject, UICollectionViewDataSource {
    private struct Constants {
        static let ReuseIdentifier = "item"
    }
    var itemDelegate: PeruseItemCollectionViewCellDelegate?
    var collectionView: UICollectionView?
    private var items = [Item]()
    private let model = Model.sharedInstance()
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "itemsUpdated", name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
      //model.fetchItemsWithinRangeAndPrivacy()
    }
    func itemsUpdated() {
        println("items updated")
        items = model.peruseItems
        collectionView?.reloadData()
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
        cell.item = indexPath.item < items.count ? items[indexPath.item] : nil
        cell.delegate = itemDelegate
        cell.setNeedsDisplay()
        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
}