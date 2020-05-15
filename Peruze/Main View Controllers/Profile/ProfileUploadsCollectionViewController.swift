//
//  ProfileUploadsCollectionViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 06/01/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileUploadsCollectionViewController: PeruseViewController {
    
    private struct Constants {
        static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    }
    var dataSource: ProfileUploadsDataSource?
    var indexOfItemToShow: Int!
    
    var segueFrom: String!
    
    override func viewDidLoad() {
//        super.viewDidLoad()
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
            if NSUserDefaults.standardUserDefaults().valueForKey("UploadedItemIndex") != nil {
                let indexPath = NSIndexPath(forItem: NSUserDefaults.standardUserDefaults().valueForKey("UploadedItemIndex") as! Int, inSection: 0)
                logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) scroll to indexPath: \(indexPath)")
                self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
                NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "UploadedItemIndex")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
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