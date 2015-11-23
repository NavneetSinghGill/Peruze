//
//  PeruseViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/1/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit

class PeruseViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PeruseItemCollectionViewCellDelegate, PeruseExchangeViewControllerDelegate {
  private struct Constants {
    static let BufferSize:CGFloat = 16
    static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    static let ProfileNavigationControllerIdentifier = "ProfileNavigationController"
  }
  
  private lazy var dataSource = PeruseItemDataSource()
  private var itemToForwardToExchange: NSManagedObject?
    var isGetItemsInProgress: Bool?
  
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
        checkmark.frame.insetInPlace(dx: checkmark.frame.width / 4, dy: checkmark.frame.width / 4)
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
    
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setBool(true, forKey: "keyIsMoreItemsAvalable")
    defaults.synchronize()
    
    //Register for push notifications
    let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    UIApplication.sharedApplication().registerForRemoteNotifications()
    
    //register data source for updates to model
    NSNotificationCenter.defaultCenter().addObserver(dataSource, selector: "performFetchWithPresentationContext:",
      name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: self)
    
    //register self for updates notifications
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: "receivedNotification:",
      name: NSManagedObjectContextObjectsDidChangeNotification,
      object: managedConcurrentObjectContext)
    
    
    getMyExchanges()
  }
  func receivedNotification(notification: NSNotification) {
    let updatedObjects: NSArray? = notification.userInfo?[NSUpdatedObjectsKey] as? NSArray
    let deletedObjects: AnyObject? = notification.userInfo?[NSDeletedObjectsKey]
    let insertedObjects: NSArray? = notification.userInfo?[NSInsertedObjectsKey] as? NSArray
    
    if updatedObjects != nil {
      print("- - - - - updated objects - - - - - ")
      print("\(updatedObjects!) " )
    }
    if deletedObjects != nil {
      print("- - - - - deleted objects - - - - - ")
      print("\(deletedObjects) ")
    }
    if insertedObjects != nil {
      print("- - - - - inserted objects - - - - - ")
      print("\(insertedObjects) ")
    }
//    dispatch_async(dispatch_get_main_queue()) {
//        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "reload", object: nil, userInfo: nil))
//    }
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
    let postExchange = PostExchangeOperation(
      date: NSDate(timeIntervalSinceNow: 0),
      status: ExchangeStatus.Pending,
      itemOfferedRecordIDName: itemChosenToExchange!.valueForKey("recordIDName") as! String,
      itemRequestedRecordIDName: itemToForwardToExchange!.valueForKey("recordIDName") as! String,
      database: CKContainer.defaultContainer().publicCloudDatabase,
      context: managedConcurrentObjectContext) { /* Completion */
        dispatch_async(dispatch_get_main_queue()){
            self.dataSource.collectionView.reloadData()
        }
    }
    OperationQueue().addOperation(postExchange)
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
    print("item started favorite! ")
    let itemRecordIDName = item.valueForKey("recordIDName") as! String
    let favoriteOp = favorite ? PostFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName) : RemoveFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName)
    favoriteOp.completionBlock = {
      print("favorite completed successfully")
      self.dataSource.getFavorites()
    }
    OperationQueue().addOperation(favoriteOp)
  }
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//    if indexPath.section == 1 {
      //this is about to display the loading cell
//        if  self.isGetItemsInProgress == false {
//            self.isGetItemsInProgress = true
//            Model.sharedInstance().getPeruzeItems(self, completion: {
//                print("-------------GetPeruzeItems Finish-----------------")
//                self.isGetItemsInProgress = false
//                self.dataSource.performFetchWithPresentationContext(self)
//            })
//        }
//    }
  }
    func scrollViewDidScroll(scrollView: UIScrollView){
        if (scrollView.contentOffset.x == scrollView.contentSize.width - scrollView.frame.size.width)
        {
            let defaults = NSUserDefaults.standardUserDefaults()
            let isMoreItemsAvailable = defaults.boolForKey("keyIsMoreItemsAvalable")
            if  self.isGetItemsInProgress == false && isMoreItemsAvailable == true {
                self.isGetItemsInProgress = true
                print("\(NSDate()) Peruze view - GetPeruzeItems called for more items")
                Model.sharedInstance().getPeruzeItems(self, completion: {
                    print("\(NSDate()) Peruze view - More GetPeruzeItems completed!")
                    self.isGetItemsInProgress = false
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "reload", object: nil, userInfo: nil))
                })
            }
        }
    }
    
    func getMyExchanges() {
        
        var personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
//        if personForProfile.exchanges?.count == 0 {
            let personForProfileRecordID = personForProfile?.valueForKey("recordIDName") as! String
            let personRecordID = CKRecordID(recordName: personForProfile?.valueForKey("recordIDName") as! String)
        
        let fetchPersonOperation = GetPersonOperation(recordID: personRecordID, database: CKContainer.defaultContainer().publicCloudDatabase , context: managedConcurrentObjectContext)
        fetchPersonOperation.completionBlock = {
            print("Finished FetchPersonOperation")
            let fetchExchangesOperation: GetAllParticipatingExchangesOperation
            fetchExchangesOperation = GetAllParticipatingExchangesOperation(personRecordIDName: personRecordID.recordName,
                status: ExchangeStatus.Pending, database: CKContainer.defaultContainer().publicCloudDatabase, context: managedConcurrentObjectContext)
            fetchExchangesOperation.completionBlock = {
                print("Finished fetchExchangesOperation \(personForProfileRecordID)")
                personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
                //                self.dataSource.performFetchWithPresentationContext(self)
                self.getAllItems()
            }
            OperationQueue().addOperation(fetchExchangesOperation)
            //        }
        }
        OperationQueue().addOperation(fetchPersonOperation)
    }
    
    func getAllItems() {
        isGetItemsInProgress = true
        
        print("\(NSDate()) Peruze view - GetPeruzeItems called")
        Model.sharedInstance().getPeruzeItems(self, completion: {
            self.isGetItemsInProgress = false
            self.dataSource.performFetchWithPresentationContext(self)
            print("\(NSDate()) Peruze view - GetPeruzeItems completed!")
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
//                self.getMyExchanges()
            }
        })
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
