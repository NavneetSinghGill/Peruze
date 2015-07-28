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
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let myID = me.valueForKey("recordIDName") as! String
    fetchRequest.predicate = NSPredicate(format: "owner.image != nil AND owner.recordIDName != %@", myID)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "image", ascending: true)]
    fetchRequest.includesSubentities = true
    fetchRequest.returnsObjectsAsFaults = false
    fetchRequest.includesPropertyValues = true
    fetchRequest.relationshipKeyPathsForPrefetching = ["owner", "owner.image", "owner.firstName"]
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
    let item = fetchedResultsController.objectAtIndexPath(indexPath)
    
    guard
      let itemImageData = item.valueForKey("image") as? NSData,
      let itemTitle = item.valueForKey("title") as? String,
      let itemDetail = item.valueForKey("detail") as? String,
      let itemRecordIDName = item.valueForKey("recordIDName") as? String
      else {
        cell.item = errorCell()
        cell.setNeedsDisplay()
        return cell
    }
    guard
      let itemOwner = item.valueForKey("owner") as? NSManagedObject,
      let ownerFirstName = itemOwner.valueForKey("firstName") as? String,
      let ownerImageData = itemOwner.valueForKey("image") as? NSData,
      let ownerRecordID = itemOwner.valueForKey("recordIDName") as? String
      else {
        print("issue with the owner of the item")
        cell.item = errorCell()
        cell.setNeedsDisplay()
        return cell
    }
    
    let localOwner = OwnerStruct(
      image: UIImage(data: ownerImageData)!,
      formattedName: ownerFirstName,
      recordIDName: ownerRecordID
    )
    let localItem = ItemStruct(
      image: UIImage(data: itemImageData)!,
      title: itemTitle,
      detail: itemDetail,
      owner: localOwner,
      recordIDName: itemRecordIDName
    )
    
    cell.item = localItem
    cell.delegate = itemDelegate
    cell.setNeedsDisplay()
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    
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