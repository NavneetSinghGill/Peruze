//
//  PeruseViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/1/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

extension PeruseViewController : InfiniteCollectionViewDelegate {
    func didSelectCellAtIndexPath(collectionView: UICollectionView, usableIndexPath: NSIndexPath) {
        
    }
}

class PeruseViewController: UIViewController, UICollectionViewDelegateFlowLayout, PeruseItemCollectionViewCellDelegate, PeruseExchangeViewControllerDelegate {
  private struct Constants {
    static let BufferSize:CGFloat = 16
    static let ExchangeSegueIdentifier = "toOfferToExchangeView"
    static let ProfileNavigationControllerIdentifier = "ProfileNavigationController"
  }
  
  private lazy var dataSource = PeruseItemDataSource()
  private var itemToForwardToExchange: NSManagedObject?
    var isGetItemsInProgress: Bool?
    
    var timer : NSTimer? = nil
  
  //the item the user owns that he/she selected to exchange
  var itemChosenToExchange: NSManagedObject? {
    didSet {
        if itemChosenToExchange != nil {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) itemChosenToExchange: \(itemChosenToExchange)")
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
        if self.dataSource.collectionView != nil {
            dispatch_async(dispatch_get_main_queue()){
                self.dataSource.collectionView.reloadData()
            }
        }
        UIView.animateWithDuration(1, animations: { () -> Void in
          circle.alpha = 0.0
          checkmark.alpha = 0.0
          }, completion: { (_) -> Void in
            circle.removeFromSuperview()
            checkmark.removeFromSuperview()
        })
        self.exchangeInitiated()
      }
    }
  }
  @IBOutlet weak var collectionView: InfiniteCollectionView! {
    didSet {
      dataSource.collectionView = collectionView
      dataSource.itemDelegate = self
//      collectionView.dataSource = dataSource
//      collectionView.delegate = self
        collectionView.infiniteDataSource = dataSource
        collectionView.infiniteDelegate = self
      collectionView.pagingEnabled = true
      collectionView.showsHorizontalScrollIndicator = false
    }
  }
    
    func performt(notification: NSNotification) {
        let  userInfo = notification.userInfo
        let alert = UIAlertController(title: "NOTIFICATION", message: "\(userInfo)", preferredStyle: UIAlertControllerStyle.Alert)
        let doDelete = UIAlertAction(title: "ok", style: UIAlertActionStyle.Destructive) { (alertAction) -> Void in
        }
        alert.addAction(doDelete)
        self.presentViewController(alert, animated: true, completion: nil)
    
    }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "update", userInfo: nil, repeats: true)
    
    //Register for push notifications
    let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
//    let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil)
    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    UIApplication.sharedApplication().registerForRemoteNotifications()
    
    //register data source for updates to model
    NSNotificationCenter.defaultCenter().addObserver(dataSource, selector: "performFetchWithPresentationContext:",
      name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: self)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "performt:",
        name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: self)
    
    //register self for updates notifications
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: "receivedNotification:",
      name: NSManagedObjectContextObjectsDidChangeNotification,
      object: managedConcurrentObjectContext)
    
    //call on settings itmes filter change
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateItemsOnFilterChange",
        name: NotificationCenterKeys.UpdateItemsOnFilterChange, object: self)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateItemsOnFilterChange", name: "LNUpdateItemsOnFilterChange", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadPeruseItemMainScreen:", name: "reloadPeruseItemMainScreen", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeItemFromLocalDB:", name: "removeItemFromLocalDB", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadPeruseItemMainScreen:", name: "justReloadPeruseItemMainScreen", object: nil)
    let logo = UIImage(named: "Peruse_Typography_Thick.jpeg")
    let imageView = UIImageView(image:logo)
    imageView.frame.size.width = 100;
    imageView.frame.size.height = 35;
    imageView.contentMode = UIViewContentMode.ScaleAspectFit
    self.navigationItem.titleView = imageView
    self.navigationController!.navigationBar.barTintColor = UIColor.whiteColor()
    
    NSUserDefaults.standardUserDefaults().setBool(false, forKey: UniversalConstants.kIsScreenRefreshInProgress)
    NSUserDefaults.standardUserDefaults().synchronize()
    if dataSource.fetchedResultsController.sections?[0].numberOfObjects == 0 {
        self.getMyExchanges()
    } else {
        self.dataSource.refreshData(self, shouldShuffle: true)
        NSUserDefaults.standardUserDefaults().setObject("yes", forKey: "shouldCallWithSyncDate")
        self.getAllItems()
    }
    NSUserDefaults.standardUserDefaults().setValue("yes", forKey: "oneTimeCallForItems")
    Model.sharedInstance().getAllDeleteUsers()
  }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.valueForKey(UniversalConstants.kSetSubscriptions) == nil || defaults.valueForKey(UniversalConstants.kSetSubscriptions) as! Bool == true {
            Model.sharedInstance().subscribeForNewOffer()
            defaults.setValue(false, forKey: UniversalConstants.kSetSubscriptions)
            defaults.synchronize()
        }
        
        let weekTimeInSeconds = 7 * 24 * 60 * 60.0
        if defaults.valueForKey("LastFetchTaggagleFriendsDate") == nil || NSDate().timeIntervalSince1970 - (defaults.valueForKey("LastFetchTaggagleFriendsDate") as! NSDate).timeIntervalSince1970 > weekTimeInSeconds {
            defaults.setValue(NSDate(), forKey: "LastFetchTaggagleFriendsDate")
            defaults.synchronize()
            Model.sharedInstance().fetchTaggleFriendsRecordFromCloud() {
                dispatch_async(dispatch_get_main_queue()){
                    Model.sharedInstance().getTaggableFriends()
                }
            }
        }
        if defaults.valueForKey("oneTimeCallForItems") == nil {
            if dataSource.fetchedResultsController.sections?[0].numberOfObjects == 0 {
                self.getMyExchanges()
            } else {
                self.dataSource.refreshData(self, shouldShuffle: true)
                NSUserDefaults.standardUserDefaults().setObject("yes", forKey: "shouldCallWithSyncDate")
                self.getAllItems()
            }
            NSNotificationCenter.defaultCenter().postNotificationName("oneTimeFetch", object: nil)
            defaults.setValue("yes", forKey: "oneTimeCallForItems")
        }
        self.dataSource.refreshData(self, shouldShuffle: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        //        }
    }
    
    func reloadPeruseItemMainScreen(notification: NSNotification){
        if notification.userInfo != nil {
            let userInfo : NSDictionary = notification.userInfo!
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) notification.userInfo: \(userInfo)")
            if let _ = userInfo.valueForKey("shouldShuffle") as? String {
                self.reloadWithShuffle(true)
            } else {
                self.reloadWithShuffle(false)
            }
        } else {
            self.reloadWithShuffle(false)
        }
    }
    
    func reloadWithShuffle(shouldShuffle: Bool = true) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) shouldShuffle: \(shouldShuffle)")
        self.dataSource.refreshData(self, shouldShuffle: shouldShuffle)
    }
    
    func removeItemFromLocalDB(notification:NSNotification) {
        if notification.userInfo != nil {
            let userInfo : NSDictionary = notification.userInfo!
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) notification.userinfo: \(userInfo)")
            let recordID = userInfo.valueForKey("recordID")
            if recordID != nil {
                let itemToDelete = Item.MR_findFirstByAttribute("recordIDName", withValue: recordID, inContext: managedConcurrentObjectContext)
                do {
                    if itemToDelete != nil {
                        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
                        var fav: NSSet!
                        if let favorites = me.valueForKey("favorites") as? NSSet {
                            if let favoriteObjs = favorites.allObjects as? [NSManagedObject] {
                                for favoriteObj in favoriteObjs{
                                    if favoriteObj.valueForKey("hasRequested") != nil && favoriteObj.valueForKey("title") != nil && favoriteObj.valueForKey("hasRequested") as! String == "no"  {
//                                        fav.append(favoriteObj)
                                        fav = NSSet(array: fav.allObjects + [favoriteObj])
                                    }
                                }
                            }
                        }
                        let newFavorites = NSSet(array: fav.allObjects)
                        me.setValue(newFavorites, forKey: "favorites")
                        let localItem = try managedConcurrentObjectContext.existingObjectWithID(itemToDelete.objectID)
                        managedConcurrentObjectContext.deleteObject(localItem)
                    }
                } catch {
                    logw("PeruseViewController removeItemFromLocalDB failed with error: \(error)")
                }
                
                logw("Deleting Single Item from Persistent Store and Waiting...")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                reloadWithShuffle()
            }
        }
    }
    
  func receivedNotification(notification: NSNotification) {
    let updatedObjects: NSArray? = notification.userInfo?[NSUpdatedObjectsKey] as? NSArray
    let deletedObjects: AnyObject? = notification.userInfo?[NSDeletedObjectsKey]
    let insertedObjects: NSArray? = notification.userInfo?[NSInsertedObjectsKey] as? NSArray
    
    if updatedObjects != nil {
      logw("- - - - - updated objects - - - - - ")
      logw("\(updatedObjects!) " )
    }
    if deletedObjects != nil {
      logw("- - - - - deleted objects - - - - - ")
      logw("\(deletedObjects) ")
    }
    if insertedObjects != nil {
      logw("- - - - - inserted objects - - - - - ")
      logw("\(insertedObjects) ")
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
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) item: \(item)")
    if item.valueForKey("hasRequested") as! String == "yes" {
        let alert = UIAlertController(title: "Exchange", message: "This item is already requested.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    } else {
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        itemToForwardToExchange = item
        if let _ = itemToForwardToExchange?.valueForKey("imageUrl") as? String,
            let _ = itemToForwardToExchange?.valueForKey("owner")!.valueForKey("imageUrl") as? String{
                performSegueWithIdentifier(Constants.ExchangeSegueIdentifier, sender: self)
    }
    }
    }
  
    private func exchangeInitiated() {
     //TODO: create an exchange and pass it to the data model
    let postExchange = PostExchangeOperation(date: NSDate(timeIntervalSinceNow: 0),
      status: ExchangeStatus.Pending,
      itemOfferedRecordIDName: itemChosenToExchange!.valueForKey("recordIDName") as! String,
      itemRequestedRecordIDName: itemToForwardToExchange!.valueForKey("recordIDName") as! String,
      database: CKContainer.defaultContainer().publicCloudDatabase,
      context: managedConcurrentObjectContext,
        errorBlock: {dispatch_async(dispatch_get_main_queue()){
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while exchanging item.", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            dispatch_async(dispatch_get_main_queue()){
                self.dataSource.collectionView.reloadData()
            }
            }
        }) { /* Completion */
        dispatch_async(dispatch_get_main_queue()){
            self.dataSource.collectionView.reloadData()
        }
    }
    OperationQueue().addOperation(postExchange)
  }
  
    func segueToProfile(ownerID: String) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) ownerID: \(ownerID)")
    let profileNav = storyboard!.instantiateViewControllerWithIdentifier(Constants.ProfileNavigationControllerIdentifier) as? UINavigationController
    if profileNav == nil { assertionFailure("profile navigation view controller from storyboard is nil") }
    let profileVC = profileNav?.viewControllers[0] as? ProfileViewController
    if profileVC == nil { assertionFailure("profile view controller from storybaord is nil") }
    profileVC!.personForProfile = Person.MR_findFirstByAttribute("recordIDName", withValue: ownerID)
    profileVC!.isShowingMyProfile = false
    presentViewController(profileNav!, animated: true, completion: nil)
  }
  
    func itemFavorited(item: NSManagedObject, favorite: Bool) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) favorite: \(favorite), item: \(item)")
    //favorite data
    logw("item started favorite! ")
    let itemRecordIDName = item.valueForKey("recordIDName") as! String
    let favoriteOp = favorite ? PostFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName) : RemoveFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName)
    favoriteOp.completionBlock = {
      logw("favorite completed successfully")
      self.dataSource.getFavorites()
        NSNotificationCenter.defaultCenter().postNotificationName("justReloadPeruseItemMainScreen", object: nil)
    }
    OperationQueue().addOperation(favoriteOp)
  }
  
  func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//    if indexPath.section == 1 {
      //this is about to display the loading cell
//        if  self.isGetItemsInProgress == false {
//            self.isGetItemsInProgress = true
//            Model.sharedInstance().getPeruzeItems(self, completion: {
//                logw("-------------GetPeruzeItems Finish-----------------")
//                self.isGetItemsInProgress = false
//                self.dataSource.performFetchWithPresentationContext(self)
//            })
//        }
//    }
  }
    func scrollViewDidScroll(scrollView: UIScrollView){
        if (scrollView.contentOffset.x == scrollView.contentSize.width - scrollView.frame.size.width)
        {
            getMoreItems()
        }
    }
    
    func getMyExchanges() {
         
        //Setting more data available controlling functionality
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: "keyIsMoreItemsAvalable")
        defaults.synchronize()
        
        //Retrive user from DB
        var personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
        //        if personForProfile.exchanges?.count == 0 {
        let personForProfileRecordID = personForProfile?.valueForKey("recordIDName") as! String
        let personRecordID = CKRecordID(recordName: personForProfile?.valueForKey("recordIDName") as! String)
        
//        //Delete all items of peruze tab
//        let myRequestedPredicate = NSPredicate(format: "owner.recordIDName != %@ ", personForProfileRecordID)
//        Item.MR_deleteAllMatchingPredicate(myRequestedPredicate, inContext: managedConcurrentObjectContext)
//        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        
        //Refresh view items
//        self.dataSource.performFetchWithPresentationContext(self)
        
        //fetch exchanges, items
        let fetchPersonOperation = GetPersonOperation(recordID: personRecordID, database: CKContainer.defaultContainer().publicCloudDatabase , context: managedConcurrentObjectContext)
        fetchPersonOperation.completionBlock = {
            logw("Finished FetchPersonOperation")
            let fetchExchangesOperation: GetAllParticipatingExchangesOperation
            fetchExchangesOperation = GetAllParticipatingExchangesOperation(personRecordIDName: personRecordID.recordName,
                status: ExchangeStatus.Pending, database: CKContainer.defaultContainer().publicCloudDatabase, context: managedConcurrentObjectContext)
            fetchExchangesOperation.completionBlock = {
                logw("Finished fetchExchangesOperation \(personForProfileRecordID)")
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
        logw("\(NSDate())>>>>> Peruze view - GetPeruzeItems called")
        Model.sharedInstance().getPeruzeItems(self, completion: {
            self.isGetItemsInProgress = false
//            self.dataSource.refreshData(self)
            self.refreshItemsIfRetrivedFromCloud()
            logw("\(NSDate())<<<<< Peruze view - GetPeruzeItems completed!")
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "FetchUserProfileIfNeeded", object: nil, userInfo: nil))
            self.getAllPersonsMissingData()
        })
    }
    
    func getAllPersonsMissingData() {
         let fillMissingPeopleData = GetAllPersonsWithMissingData(database: CKContainer.defaultContainer().publicCloudDatabase, context: managedConcurrentObjectContext)
        fillMissingPeopleData.completionBlock = {
            logw("\n\n\(NSDate())===== fillMissingPeopleData Completed======")
        }
        OperationQueue().addOperation(fillMissingPeopleData)
    }
    
    func getMoreItems() {
         let defaults = NSUserDefaults.standardUserDefaults()
        let isMoreItemsAvailable = defaults.boolForKey("keyIsMoreItemsAvalable")
         if  self.isGetItemsInProgress == false {
            if isMoreItemsAvailable == true {
                self.getAllItems()
            } else {
//                logw("\n\n\(NSDate()) ----------------  Timer Stopped ----------------------")
                self.timer!.invalidate()
                self.timer = NSTimer.scheduledTimerWithTimeInterval(15*60, target: self, selector: "update", userInfo: nil, repeats: true)
                NSUserDefaults.standardUserDefaults().setObject("yes", forKey: "shouldCallWithSyncDate")
                self.getAllItems()
            }
        }
    }
    
    // Method calls when filter changed from the setting screen
    func updateItemsOnFilterChange() {
            dispatch_async(dispatch_get_main_queue()) {
               self.dataSource.refreshData(self, shouldShuffle: false)
            }
    }
    
    func update() {
         logw("\n\n\(NSDate()) ----------------  Timer started ----------------------")
        getMoreItems()
    }
    
    func refreshItemsIfRetrivedFromCloud() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.boolForKey("keyHasDataRetrivedFromCloud")) {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) keyHasDataRetrivedFromCloud: \(defaults.boolForKey("keyHasDataRetrivedFromCloud"))")
            self.dataSource.refreshData(self, shouldShuffle: false)
        } else {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) keyHasDataRetrivedFromCloud key is nil")
        }
    }
    
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == Constants.ExchangeSegueIdentifier {
        if let destVC = segue.destinationViewController as? PeruseExchangeViewController{
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) itemToForwardToExchange: \(itemToForwardToExchange)")
            destVC.itemSelectedForExchange = itemToForwardToExchange
            destVC.delegate = self
      }
    }
  }

}
