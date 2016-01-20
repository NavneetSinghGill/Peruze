//
//  ProfileUploadsCollectionViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 06/01/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import UIKit

class ProfileUploadsCollectionViewController: PeruseViewController {
    
    private struct Constants {
        static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    }
    var dataSource: ProfileUploadsDataSource?
    var indexOfItemToShow: Int!
    
    var segueFrom: String!
    
    override func viewDidLoad() {
        //    super.viewDidLoad()
        //TODO: - Pass this variable in instead of setting it
//        dataSource = ProfileUploadsDataSource()
//        self.title = "Upload"
        navigationController?.navigationBar.tintColor = .redColor()
        tabBarController?.tabBar.hidden = true
        dataSource!.itemDelegate = self
        collectionView.infiniteDataSource = dataSource
        let leftBarButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backButtonTapped")
        self.navigationItem.setLeftBarButtonItem(leftBarButton, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatch_async(dispatch_get_main_queue()){
//            self.collectionView.reloadData()
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
//        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let indexPath = NSIndexPath(forItem: NSUserDefaults.standardUserDefaults().valueForKey("UploadedItemIndex") as! Int, inSection: 0)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
//            }
        }
    }
    
    func backButtonTapped() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
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