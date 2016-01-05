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
      dataSource.requestDelegate = self
      collectionView.dataSource = dataSource
      collectionView.delegate = self
      collectionView.pagingEnabled = true
      collectionView.showsHorizontalScrollIndicator = false
    }
  }
  
    var parentVC: UIViewController!
    
  private var storedTop: CGFloat = 0
  private var storedBottom: CGFloat = 0
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let layout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
    let top = navigationController?.navigationBar.frame.maxY ?? storedTop
    if storedTop == 0 { storedTop = top }
    let bottom = tabBarController?.tabBar.frame.height ?? storedBottom
    if storedBottom == 0 { storedBottom = bottom }
    let left: CGFloat = 0
    let right: CGFloat = 0
    let insets = UIEdgeInsetsMake(top, left, bottom, right)
    collectionView.scrollIndicatorInsets = insets
    let cellSize = CGSizeMake(collectionView.frame.width, view.frame.height - bottom - top)
    layout.itemSize = cellSize
    layout.sectionInset = insets
    collectionView.reloadData()
    if let indexPath = indexPathToScrollToOnInit {
      if collectionView.numberOfItemsInSection(0) <= indexPath.item { return }
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
  
    func requestAccepted(request: Exchange) {
        let deletedItemIndexPath = dataSource.acceptRequest(request)
        // number of objects = 1 will be 0 since deny request will be send in follwoing lines.
        if self.dataSource.fetchedResultsController.sections![0].numberOfObjects == 1 {
            self.navigationController?.popViewControllerAnimated(true)
        }
        if let parent = self.parentVC as? RequestsTableViewController {
            parent.acceptExchangeAtIndexPath(deletedItemIndexPath,completionBlock: {
            })
        }
        collectionView.reloadData()
//    collectionView.deleteItemsAtIndexPaths([deletedItemIndexPath])
//    Model.sharedInstance().acceptExchangeRequest(request, completion: { (reloadedRequests, error) -> Void in
//      self.dataSource.requests = reloadedRequests ?? []
//      self.collectionView.reloadData()
//      if error != nil {
//        ErrorAlertFactory.alertFromError(error!, dismissCompletion: nil)
//      }
//      self.checkForEmptyData()
//    })
  }
  
  func requestDenied(request: Exchange) {
    let deletedItemIndexPath = dataSource.deleteRequest(request)
    // number of objects = 1 will be 0 since deny request will be send in follwoing lines.
    if self.dataSource.fetchedResultsController.sections![0].numberOfObjects == 1 {
        self.navigationController?.popViewControllerAnimated(true)
    }
    if let parent = self.parentVC as? RequestsTableViewController {
        parent.denyExchangeAtIndexPath(deletedItemIndexPath,completionBlock: {
        })
    }
    collectionView.reloadData()
//    collectionView.deleteItemsAtIndexPaths([deletedItemIndexPath])
//    Model.sharedInstance().denyExchangeRequest(request, completion: { (reloadedRequests, error) -> Void in
//      self.dataSource.requests = reloadedRequests ?? []
//      self.collectionView.reloadData()
//      if error != nil {
//        ErrorAlertFactory.alertFromError(error!, dismissCompletion: nil)
//      }
//      self.checkForEmptyData()
//    })
  }
}
