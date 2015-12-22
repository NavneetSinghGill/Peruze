//
//  ProfileFavoritesCollectionViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/29/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit

class ProfileFavoritesCollectionViewController: PeruseViewController {
  
  private struct Constants {
    static let ExchangeSegueIdentifier = "toOfferToExchangeView"
  }
  var dataSource: ProfileFavoritesDataSource?
    var indexOfItemToShow: Int!
  
  override func viewDidLoad() {
//    super.viewDidLoad()
    //TODO: - Pass this variable in instead of setting it
    dataSource = ProfileFavoritesDataSource()
    self.title = "Favorites"
    navigationController?.navigationBar.tintColor = .redColor()
    tabBarController?.tabBar.hidden = true
    dataSource!.itemDelegate = self
    collectionView.dataSource = dataSource
  }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let indexPath = NSIndexPath(forItem: NSUserDefaults.standardUserDefaults().valueForKey("FavouriteIndex") as! Int, inSection: 0)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
        }
    }
    
  var storedTop: CGFloat = 0
  var storedBottom: CGFloat = 0
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let layout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
    let top = navigationController?.navigationBar.frame.maxY ?? storedTop
    if storedTop == 0 { storedTop = top }
    let bottom = view.frame.maxY
    let left: CGFloat = 0
    let right: CGFloat = 0
    let insets = UIEdgeInsetsMake(top, left, bottom, right)
    collectionView.scrollIndicatorInsets = insets
    let cellSize = CGSizeMake(collectionView.frame.width, bottom - top)
    layout.itemSize = cellSize
  }
}
