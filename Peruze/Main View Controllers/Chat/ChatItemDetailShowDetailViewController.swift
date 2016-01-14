//
//  ChatItemDetailShowDetailViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 14/01/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import UIKit
import SwiftLog

class ChatItemDetailShowDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private struct Constants {
        static let ReuseIdentifier = "item"
        static let LoadingReuseIdentifier = "loading"
        static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    }
    
    var collectionView: UICollectionView!{
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
//            collectionView.pagingEnabled = true
//            collectionView.showsHorizontalScrollIndicator = false
        }
    }
    var manageObjectItems = [NSManagedObject]()
    var items: NSArray!
    
    ///the .recordIDName's of the favorite items
    var favorites = [String]()
    
    override func viewDidLoad() {
        //    super.viewDidLoad()
        //TODO: - Pass this variable in instead of setting it
        //        dataSource = ProfileUploadsDataSource()
        self.title = "Item Detail"
        navigationController?.navigationBar.tintColor = .redColor()
        tabBarController?.tabBar.hidden = true
        let leftBarButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backButtonTapped")
        self.navigationItem.setLeftBarButtonItem(leftBarButton, animated: true)
        
        items = manageObjectItems as! [Item]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func backButtonTapped() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: NSBundle.mainBundle())
        let loadingNib = UINib(nibName: "PeruseLoadingCollectionViewCell", bundle: NSBundle.mainBundle())
        
        collectionView.registerNib(loadingNib, forCellWithReuseIdentifier: Constants.LoadingReuseIdentifier)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
        let localCell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
        
        localCell.scrollView.alwaysBounceVertical = false
        let item = self.items[indexPath.row]
        localCell.item = item as? NSManagedObject
        localCell.itemFavorited = self.favorites.filter{ $0 == (item.valueForKey("recordIDName") as! String) }.count != 0
        localCell.setNeedsDisplay()
        return localCell
    }
    
    func getFavorites() {
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
        var trueFavorites = [NSManagedObject]()
        if let favorites = (me.valueForKey("favorites") as? NSSet)?.allObjects as? [NSManagedObject] {
            for favoriteObj in favorites {
                if favoriteObj.valueForKey("hasRequested") != nil && favoriteObj.valueForKey("title") != nil && favoriteObj.valueForKey("hasRequested") as! String == "no" {
                    trueFavorites.append(favoriteObj)
                }
            }
            self.favorites = trueFavorites.map { $0.valueForKey("recordIDName") as! String }
        } else {
            logw("me.valueForKey('favorites') was not an NSSet ")
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