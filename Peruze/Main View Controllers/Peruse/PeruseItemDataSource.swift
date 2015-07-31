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
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "recordIDName", ascending: true)]
    fetchRequest.includesSubentities = true
    fetchRequest.returnsObjectsAsFaults = false
    fetchRequest.includesPropertyValues = true
    fetchRequest.relationshipKeyPathsForPrefetching = ["owner", "owner.image", "owner.firstName"]
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedConcurrentObjectContext, sectionNameKeyPath: nil, cacheName: "PeruseItemDataSourceCache")
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
    
    cell.item = item
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