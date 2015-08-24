//
//  PeruseItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/2/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

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

class PeruseItemDataSource: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    static let ReuseIdentifier = "item"
    static let LoadingReuseIdentifier = "loading"
  }
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var collectionView: UICollectionView!
  var fetchedResultsController: NSFetchedResultsController!
  var favorites = [NSManagedObject]()
  
  override init() {
    super.init()
    let fetchRequest = NSFetchRequest(entityName: RecordTypes.Item)
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let myID = me.valueForKey("recordIDName") as! String
    fetchRequest.predicate = NSPredicate(format: "owner.recordIDName != %@", myID)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "recordIDName", ascending: true)]
    fetchRequest.includesSubentities = true
    fetchRequest.returnsObjectsAsFaults = false
    fetchRequest.includesPropertyValues = true
    fetchRequest.relationshipKeyPathsForPrefetching = ["owner", "owner.image", "owner.firstName", "owner.recordIDName"]
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedConcurrentObjectContext, sectionNameKeyPath: nil, cacheName: "PeruseItemDataSourceCache")
    fetchedResultsController.delegate = self
    
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    if error != nil {
      print(error)
    }
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "performFetch",
      name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
  }
  
  ///fetches the results from the fetchedResultsController
  func performFetchWithPresentationContext(presentationContext: UIViewController) {
    print("Perform Fetch")
    dispatch_async(dispatch_get_main_queue()) {
      var error: NSError?
      self.fetchedResultsController.performFetch(&error)
      if error != nil {
        print(error)
        let alert = UIAlertController(
          title: "Oops!",
          message: ("There was an issue fetching results from your device. Error: " + error!.localizedDescription),
          preferredStyle: .Alert
        )
        alert.addAction(
          UIAlertAction(
            title: "okay",
            style: .Cancel) { (_) -> Void in
          alert.dismissViewControllerAnimated(true, completion: nil)
        })
        presentationContext.presentViewController(alert, animated: true, completion: nil)
      } else {
        self.collectionView.reloadData()
      }
    }
  }
  
  private func getFavorites() {
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    if let favorites = me.valueForKey("favorites") as? NSSet {
      if let favoriteObjs = favorites.allObjects as? [NSManagedObject] {
        self.favorites = favoriteObjs
      } else {
        print("me.valueForKey('favorites').allObjects was not an [NSManagedObject]\n")
      }
    } else {
      print("me.valueForKey('favorites') was not an NSSet\n")
    }
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    print("Will Change Context")
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    print("Did Change Object")
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    print("Did Change Context")
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: NSBundle.mainBundle())
    let loadingNib = UINib(nibName: "PeruseLoadingCollectionViewCell", bundle: NSBundle.mainBundle())
    
    collectionView.registerNib(loadingNib, forCellWithReuseIdentifier: Constants.LoadingReuseIdentifier)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    var cell: UICollectionViewCell
    if indexPath.section == 0 {
      //normal item cell
      let localCell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
      let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
      
      localCell.item = item
      localCell.delegate = itemDelegate
      localCell.setNeedsDisplay()
      cell = localCell
    } else {
      //loading cell
      cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.LoadingReuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    var returnValue = 0
    if section == 0 {
      returnValue = fetchedResultsController.sections?[section].numberOfObjects ?? 0
    } else {
      returnValue = 1
    }
    return returnValue
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 2 //normal one and then one for the loading view
  }
  
  private func errorCell() -> ItemStruct {
    let localOwner = OwnerStruct(
      image: UIImage(),
      formattedName: "",
      recordIDName: ""
    )
    return ItemStruct(
      image: UIImage(),
      title: "Error Loading Item",
      detail: "There was an error loading this item. Our apologies.",
      owner: localOwner,
      recordIDName: ""
    )
  }
  
}