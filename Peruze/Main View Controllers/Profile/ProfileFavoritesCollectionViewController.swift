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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //TODO: - Pass this variable in instead of setting it
    dataSource = ProfileFavoritesDataSource()
    self.title = "Favorites"
    navigationController?.navigationBar.tintColor = .redColor()
    tabBarController?.tabBar.hidden = true
    dataSource!.itemDelegate = self
    collectionView.dataSource = dataSource
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
    collectionView.reloadData()
  }
}
