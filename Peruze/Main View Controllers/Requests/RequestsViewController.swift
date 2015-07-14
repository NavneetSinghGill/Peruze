//
//  RequestsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/15/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class RequestsViewController: UIViewController, UICollectionViewDelegate, RequestCollectionViewCellDelegate {
    private struct Constants {
        static let BufferSize: CGFloat = 8
    }
    var indexPathToScrollToOnInit: NSIndexPath?
    var dataSource: RequestsDataSource!
    @IBOutlet weak var noRequestsLabel: UILabel! {
        didSet {
            noRequestsLabel.alpha = 0
        }
    }
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = dataSource
            collectionView.delegate = self
            collectionView.pagingEnabled = true
            collectionView.showsHorizontalScrollIndicator = false
        }
    }
    private var storedTop: CGFloat = 0
    private var storedBottom: CGFloat = 0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var layout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        let top = navigationController?.navigationBar.frame.maxY ?? storedTop
        if storedTop == 0 { storedTop = top }
        let bottom = tabBarController?.tabBar.frame.height ?? storedBottom
        if storedBottom == 0 { storedBottom = bottom }
        let left: CGFloat = 0
        let right: CGFloat = 0
        let insets = UIEdgeInsetsMake(top, left, bottom, right)
        collectionView.scrollIndicatorInsets = insets
        var cellSize = CGSizeMake(collectionView.frame.width, view.frame.height - bottom - top)
        layout.itemSize = cellSize
        layout.sectionInset = insets
        collectionView.reloadData()
        if let indexPath = indexPathToScrollToOnInit {
            collectionView.scrollToItemAtIndexPath(indexPath,
                atScrollPosition: UICollectionViewScrollPosition.None,
                animated: false)
        }
    }
    
    func checkForEmptyData() {
        if collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) == nil {
            UIView.animateWithDuration(1) {
                self.noRequestsLabel.alpha = 1.0
            }
        }
    }
    
    func requestAccepted(item: Item, forItem: Item) {
        dataSource.deleteItemAtIndex(0) //TODO: Change This
        collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
        checkForEmptyData()
    }
    
    func requestDenied(item: Item, forItem: Item) {
        dataSource.deleteItemAtIndex(0) //TODO: Change This
        collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
        checkForEmptyData()
    }
}
