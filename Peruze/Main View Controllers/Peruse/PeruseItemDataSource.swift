//
//  PeruseItemDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/2/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import MagicalRecord

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
  }
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var collectionView: UICollectionView!
  var fetchedResultsController: NSFetchedResultsController!
  private let model = Model.sharedInstance()
  override init() {
    super.init()
    let fetchRequest = NSFetchRequest(entityName: RecordTypes.Item)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "image", ascending: true)]
    fetchRequest.includesSubentities = true
    fetchRequest.includesPropertyValues = true
    fetchRequest.relationshipKeyPathsForPrefetching = ["owner", "owner.image", "owner.firstName", "owner.lastName"]
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedConcurrentObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    do {
      try fetchedResultsController.performFetch()
    } catch {
      print(error)
    }
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: "itemsUpdated", name: NotificationCenterKeys.PeruzeItemsDidFinishUpdate, object: nil)
  }
  func itemsUpdated() {
    print("items updated")
    collectionView?.reloadData()
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    print("Will Change Context")
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    print("Did Change Object")
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    print("Did Change Context")
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
    collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifier)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as! PeruseItemCollectionViewCell
    
    guard
      let item = fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject,
      let itemImageData = item.valueForKey("image") as? NSData,
      let itemTitle = item.valueForKey("title") as? String,
      let itemDetail = item.valueForKey("detail") as? String//,
//      let itemOwner = item.valueForKey("owner") as? NSManagedObject,
//      let ownerFirstName = item.valueForKey("firstName") as? String,
//      let ownerLastName = item.valueForKey("lastName") as? String,
//      let ownerImageData = item.valueForKey("image") as? NSData
      else {
        return UICollectionViewCell()
    }
    let localOwner = OwnerStruct(
      image: UIImage(data: itemImageData)!,
      formattedName: "",
      recordIDName: ""
    )
    let localItem = ItemStruct(
      image: UIImage(data: itemImageData)!,
      title: itemTitle,
      detail: itemDetail,
      owner: localOwner,
      recordIDName: ""
    )
    
    cell.item = localItem
    cell.delegate = itemDelegate
    cell.setNeedsDisplay()
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
}