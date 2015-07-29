//
//  PeruseViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/1/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import MagicalRecord

class PeruseViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PeruseItemCollectionViewCellDelegate, PeruseExchangeViewControllerDelegate {
  private struct Constants {
    static let BufferSize:CGFloat = 16
    static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    static let ProfileNavigationControllerIdentifier = "ProfileNavigationController"
  }
  
  private var dataSource = PeruseItemDataSource()
  private var itemToForwardToExchange: NSManagedObject?
  
  //the item the user owns that he/she selected to exchange
  var itemChosenToExchange: NSManagedObject? {
    didSet {
      if itemChosenToExchange != nil {
        let circle = CircleView(frame: CGRectMake(0, 0, view.frame.width, view.frame.width))
        circle.strokeColor = .greenColor()
        circle.center = CGPointMake(view.frame.width / 2, view.frame.height / 2)
        circle.backgroundColor = .clearColor()
        circle.strokeWidth = 5
        view.addSubview(circle)
        
        let checkmark = UIImageView(frame: circle.frame)
        checkmark.image = UIImage(named: "Large_Check_Mark")
        checkmark.frame.inset(dx: checkmark.frame.width / 4, dy: checkmark.frame.width / 4)
        view.addSubview(checkmark)
        
        UIView.animateWithDuration(1, animations: { () -> Void in
          circle.alpha = 0.0
          checkmark.alpha = 0.0
          }, completion: { (_) -> Void in
            circle.removeFromSuperview()
            checkmark.removeFromSuperview()
            self.exchangeInitiated()
        })
      }
    }
  }
  @IBOutlet weak var collectionView: UICollectionView! {
    didSet {
      dataSource.collectionView = collectionView
      dataSource.itemDelegate = self
      collectionView.dataSource = dataSource
      collectionView.delegate = self
      collectionView.pagingEnabled = true
      collectionView.showsHorizontalScrollIndicator = false
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //Register for push notifications
    let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    UIApplication.sharedApplication().registerForRemoteNotifications()
    
    
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: "receivedNotification:",
      name: NSManagedObjectContextObjectsDidChangeNotification,
      object: managedConcurrentObjectContext)
  }
  
  func receivedNotification(notification: NSNotification) {
    let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey]
    let deletedObjects = notification.userInfo?[NSDeletedObjectsKey]
    let insertedObjects = notification.userInfo?[NSInsertedObjectsKey]
    collectionView.reloadData()
    print("- - - - - updated objects - - - - -")
    print(updatedObjects)
    print("- - - - - deleted objects - - - - -")
    print(deletedObjects)
    print("- - - - - inserted objects - - - - -")
    print(insertedObjects)
    
  }
  
  //store top and bottom for when navigation controller is animating pop and is nil
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
    collectionView.reloadData()
  }
  
  func segueToExchange(item: NSManagedObject) {
    itemToForwardToExchange = item
    performSegueWithIdentifier(Constants.ExchangeSegueIdentifier, sender: self)
  }
  
  private func exchangeInitiated() {
    //TODO: create an exchange and pass it to the data model
  }
  
  func segueToProfile(ownerID: String) {
    let profileNav = storyboard!.instantiateViewControllerWithIdentifier(Constants.ProfileNavigationControllerIdentifier) as? UINavigationController
    if profileNav == nil { assertionFailure("profile navigation view controller from storyboard is nil") }
    let profileVC = profileNav?.viewControllers[0] as? ProfileViewController
    if profileVC == nil { assertionFailure("profile view controller from storybaord is nil") }
    profileVC!.personForProfile = Person.MR_findFirstByAttribute("recordIDName", withValue: ownerID)
    presentViewController(profileNav!, animated: true, completion: nil)
  }
  
  func itemFavorited(item: NSManagedObject, favorite: Bool) {
    //favorite data
    print("item favorited!")
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == Constants.ExchangeSegueIdentifier {
      if let destVC = segue.destinationViewController as? PeruseExchangeViewController {
        destVC.itemSelectedForExchange = itemToForwardToExchange
        destVC.delegate = self
      }
    }
  }
}
