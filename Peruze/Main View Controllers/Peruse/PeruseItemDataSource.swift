//
//  PeruseItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/2/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import Darwin

struct ItemStruct {
  var image: UIImage
  var title: String
  var detail: String
  var owner: OwnerStruct
  var recordIDName: String
}

struct OwnerStruct {
  var image: UIImage
  var formattedName: String
  var recordIDName: String
}

class PeruseItemDataSource: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UIScrollViewDelegate {
  private struct Constants {
    static let ReuseIdentifier = "item"
    static let LoadingReuseIdentifier = "loading"
  }
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var collectionView: UICollectionView!
  var fetchedResultsController: NSFetchedResultsController!
    var location =  CLLocation()
    
    var items = [Item]()
    
  ///the .recordIDName's of the favorite items
  var favorites = [String]()
  
  override init() {
    super.init()
    let fetchRequest = NSFetchRequest(entityName: RecordTypes.Item)
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let myID = me.valueForKey("recordIDName") as! String
    let predicate1 = NSPredicate(format: "owner.recordIDName != %@", myID)
    let yesString = "yes"
    let predicate2 =  NSPredicate(format: "hasRequested != %@",yesString)
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1])
    fetchRequest.predicate = compoundPredicate
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "recordIDName", ascending: true)]
    fetchRequest.includesSubentities = true
    fetchRequest.returnsObjectsAsFaults = false
    fetchRequest.includesPropertyValues = true
    fetchRequest.relationshipKeyPathsForPrefetching = ["owner", "owner.image", "owner.firstName", "owner.recordIDName"]
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedConcurrentObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    getFavorites()
    do {
      try self.fetchedResultsController.performFetch()
        
    } catch {
      print(error)
    }
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadCollectionView", name: "reload", object: nil)
  }
    func reloadCollectionView(){
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
    
  ///fetches the results from the fetchedResultsController
  func performFetchWithPresentationContext(presentationContext: UIViewController) {
    print("Perform Fetch")

    dispatch_async(dispatch_get_main_queue()) {
      do {
        try self.fetchedResultsController.performFetch()
        
//        self.refreshData(presentationContext)
      } catch {
        
        print(error)
        let alert = UIAlertController(
          title: "Oops!",
          message: ("There was an issue fetching results from your device. Error: \(error)"),
          preferredStyle: .Alert
        )
        alert.addAction(
          UIAlertAction(
            title: "okay",
            style: .Cancel) { (_) -> Void in
              alert.dismissViewControllerAnimated(true, completion: nil)
          })
        presentationContext.presentViewController(alert, animated: true, completion: nil)
      }
       
//            self.collectionView.reloadData()
//            self.getFavorites()
    }
  }
  
    
    func getDistancePredicate() -> NSPredicate {
        //        NSArray *testLocations = @[ [[CLLocation alloc] initWithLatitude:11.2233 longitude:13.2244], ... ];
        
        
        
        let maxRadius:CLLocationDistance = 45000 //Double(GetPeruzeItemOperation.userDistanceSettingInMeters())// in meters
        let targetLocation: CLLocation = self.location //CLLocation(latitude: 51.5028,longitude: 0.0031)
        //        CLLocation *targetLocation = [[CLLocation alloc] initWithLatitude:51.5028 longitude:0.0031];
        
        let predicate: NSPredicate = NSPredicate { (Item item, NSDictionary bindings) -> Bool in
            
            let itemLocation: CLLocation = CLLocation(latitude: Double( (item as! Item).latitude!),longitude: Double( (item as! Item).longitude!))
            print( (itemLocation.distanceFromLocation(targetLocation)))
            return itemLocation.distanceFromLocation(targetLocation) <= maxRadius
            
        }
        return predicate
    }
    
    
    func refreshData(presentationContext: UIViewController) {
        let opQueue = OperationQueue()
        let getLocationOp = LocationOperation(accuracy: 200) { (location) -> Void in
            self.location = location
            let allitems : NSArray = self.fetchedResultsController.sections?[0].objects as! [Item]
            self.items = allitems.filteredArrayUsingPredicate(self.getDistancePredicate()) as! [Item]
            print(self.items)
            
            self.collectionView.reloadData()
            self.getFavorites()
            
        }
        opQueue.addOperation(getLocationOp)
    }
    
    
//    func getDistancePredicate(myLocation : CLLocation) -> NSPredicate {
////        let myLocation : CLLocation =  CLLocation(latitude: 50.000, longitude: 0.2555)
////        let region : CLRegion = CLRegion(center: myLocation,radius:50 ,identifier:"dfs")
//        let   D : Double = Double(GetPeruzeItemOperation.userDistanceSettingInMeters()) * Double(1.1)
//        let   R : Double = 6371009.0 //; // Earth readius in meters Double(GetPeruzeItemOperation.userDistanceSettingInMeters())
//        let meanLatitidue : Double = myLocation.coordinate.latitude * M_PI / Double(180)
//        let deltaLatitude : Double = D / R * Double(180) / M_PI
//        let deltaLongitude : Double = D / (R * cos(meanLatitidue)) * Double(180) / M_PI;
//        let minLatitude : Double = myLocation.coordinate.latitude - deltaLatitude;
//        let maxLatitude : Double = myLocation.coordinate.latitude + deltaLatitude;
//        let minLongitude : Double = myLocation.coordinate.longitude - deltaLongitude;
//        let maxLongitude : Double = myLocation.coordinate.longitude + deltaLongitude;
//        
//        
//        
//        return NSPredicate(format:"(%@ <= longitude) AND (longitude <= %@) AND (%@ <= latitude) AND (latitude <= %@)",
//         argumentArray:[minLongitude, maxLongitude, minLatitude, maxLatitude])
//    }
  
  func getFavorites() {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    if let favorites = (me.valueForKey("favorites") as? NSSet)?.allObjects as? [NSManagedObject] {
      self.favorites = favorites.map { $0.valueForKey("recordIDName") as! String }
    } else {
      print("me.valueForKey('favorites') was not an NSSet ")
    }
  }
  
  //MARK: - NSFetchedResultsController Delegate Methods
  private var sectionChanges = [[NSFetchedResultsChangeType: Int]]()
  private var itemChanges = [[NSFetchedResultsChangeType : AnyObject]]()
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    sectionChanges = []
    itemChanges = []
  }
  
  func controller(
    controller: NSFetchedResultsController,
    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
    atIndex sectionIndex: Int,
    forChangeType type: NSFetchedResultsChangeType) {
      let change = [type : sectionIndex]
      sectionChanges.append(change)
  }
  
  func controller(controller: NSFetchedResultsController,
    didChangeObject anObject: AnyObject,
    atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType,
    newIndexPath: NSIndexPath?) {
      var change = [NSFetchedResultsChangeType : AnyObject]()
      switch type {
      case .Insert :
        change[type] = newIndexPath!
        break
      case .Delete, .Update :
        change[type] = indexPath!
        break
      case .Move :
        change[type] = [indexPath!, newIndexPath!]
        break
      }
      itemChanges.append(change)
  }
  
//  func controllerDidChangeContent(controller: NSFetchedResultsController) {
//    collectionView.performBatchUpdates({
//      //section changes
//      for change in self.sectionChanges {
//        for key in change.keys {
//          switch key {
//          case .Insert :
//            let indexSet = NSIndexSet(index: change[key]!)
//            self.collectionView.insertSections(indexSet)
//            break
//          case .Delete :
//            let indexSet = NSIndexSet(index: change[key]!)
//            self.collectionView.deleteSections(indexSet)
//            break
//          default :
//            break
//          }
//        }
//      }
//      //item changes
//      for change in self.itemChanges {
//        for key in change.keys {
//          switch key {
//          case .Insert :
//            self.collectionView.insertItemsAtIndexPaths([change[key] as! NSIndexPath])
//            break
//          case .Delete :
//            self.collectionView.deleteItemsAtIndexPaths([change[key] as! NSIndexPath])
//            break
//          case .Update :
//            self.collectionView.reloadItemsAtIndexPaths([change[key] as! NSIndexPath])
//            break
//          case .Move :
//            let fromIndex = (change[key]! as! [NSIndexPath]).first!
//            let toIndex = (change[key]! as! [NSIndexPath]).last!
//            self.collectionView.moveItemAtIndexPath(fromIndex, toIndexPath: toIndex)
//            break
//          }
//        }
//      }
//      }, completion: nil)
//  }
  
  //MARK: - UICollectionView Delegate Methods
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: NSBundle.mainBundle())
    let loadingNib = UINib(nibName: "PeruseLoadingCollectionViewCell", bundle: NSBundle.mainBundle())
    
    collectionView.registerNib(loadingNib, forCellWithReuseIdentifier: Constants.LoadingReuseIdentifier)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    var cell: UICollectionViewCell
    if indexPath.section == 0 {
      //normal item cell
      let localCell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
//      let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
      let item = self.items[indexPath.row]
        
      localCell.item = item
      localCell.itemFavorited = self.favorites.filter{ $0 == (item.valueForKey("recordIDName") as! String) }.count != 0
      localCell.delegate = itemDelegate
      localCell.setNeedsDisplay()
      cell = localCell
    } else {
      //loading cell
      cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.LoadingReuseIdentifier, forIndexPath: indexPath)
        let defaults = NSUserDefaults.standardUserDefaults()
        let isMoreItemsAvailable = defaults.boolForKey("keyIsMoreItemsAvalable")
        let view : UIView = cell.viewWithTag(3)!
        if  isMoreItemsAvailable == false {
            view.hidden = false
        } else {
            view.hidden = true
        }
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    var returnValue = 0
    if section == 0 {
//      returnValue = fetchedResultsController.sections?[section].numberOfObjects ?? 0
        returnValue = self.items.count
    } else {
      returnValue = 1
    }
    return returnValue
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//    return (fetchedResultsController.sections?.count ?? 0) + 1 //one for the loading view
    return 2
  }
    

}