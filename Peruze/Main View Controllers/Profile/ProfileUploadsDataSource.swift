//
//  ProfileUploadsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

extension ProfileUploadsDataSource: InfiniteCollectionViewDataSource {
    func numberOfItems(collectionView: UICollectionView) -> Int
    {
        var returnValue = 0
        if fetchedResultsController?.sections?[0].numberOfObjects == 0 {
            returnValue = 1
        } else {
            returnValue = (fetchedResultsController?.sections?[0].numberOfObjects)!
        }
        return returnValue
    }
    
    func cellForItemAtIndexPath(collectionView: UICollectionView, dequeueIndexPath: NSIndexPath, usableIndexPath: NSIndexPath)  -> UICollectionViewCell
    {
        let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifiers.CollectionViewCell)
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifiers.CollectionViewCell, forIndexPath: dequeueIndexPath) as! PeruseItemCollectionViewCell)
        
        let numberOfObjects = (fetchedResultsController?.sections?[0].numberOfObjects)
        var modifiedIndexpath = dequeueIndexPath
        modifiedIndexpath = NSIndexPath(forItem: dequeueIndexPath.row % numberOfObjects!, inSection: dequeueIndexPath.section)
        let item = fetchedResultsController.objectAtIndexPath(modifiedIndexpath) as! NSManagedObject
        cell.item = item
        cell.delegate = itemDelegate
        cell.itemFavorited = true
        cell.setNeedsDisplay()
        return cell
    }
}

class ProfileUploadsDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  
  private struct Constants {
    static let ReuseIdentifier = "ProfileUpload"
    static let NibName = "ProfileUploadsTableViewCell"
    struct ReuseIdentifiers {
        static let TableViewCell = "ProfileUpload"
        static let CollectionViewCell = "item"
    }
  }
  
  //TODO: Get items
  var tableView: UITableView!
  var fetchedResultsController: NSFetchedResultsController!
  var currentlyTappedUploadedItem: NSManagedObject?
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var personRecordID: String! {
    didSet {
      if personRecordID == nil { return }
      self.fetchAndReloadLocalContent()
        if tableView != nil {
            tableView.reloadData()
        }
    }
  }
  var tempImageView = UIImageView()
  override init() {
    super.init()
    currentlyTappedUploadedItem = Item.MR_findFirst()
    if personRecordID == nil {
      return
    }
    fetchAndReloadLocalContent()
  }
    
    func fetchAndReloadLocalContent() -> Int {
        if personRecordID == nil { return 0}
        let predicate = NSPredicate(format: "owner.recordIDName = %@", personRecordID)
        let predicateForDeletedItem = NSPredicate(format: "isDelete != 1")
        fetchedResultsController = Item.MR_fetchAllSortedBy("title",
            ascending: true,
            withPredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicateForDeletedItem]),
            groupBy: nil, delegate: self,
            inContext: managedConcurrentObjectContext)
        do {
            try fetchedResultsController.performFetch()
            dispatch_async(dispatch_get_main_queue()) {
                if self.tableView != nil {
                    self.tableView.reloadData()
                }
            }
        } catch {
            logw("ProfileUploads local data fetch failed with error: \(error)")
        }
        return fetchedResultsController.sections![0].numberOfObjects
    }
  
  var editableCells = true
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
      forIndexPath: indexPath) as! ProfileUploadsTableViewCell
    
    let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
    
    cell.titleTextLabel.text = (item.valueForKey("title") as! String)
    cell.subtitleTextLabel.text = ""
    cell.descriptionTextLabel.text = (item.valueForKey("detail") as! String)
    
//    if item.valueForKey("imageUrl") != nil {
//        tempImageView = UIImageView()
//        tempImageView.sd_setImageWithURL(NSURL(string: s3Url(item.valueForKey("imageUrl") as! String)), completed: { (image, error, sdImageCacheType, url) -> Void in
//            cell.circleImageView.image = image
//            cell.contentView.setNeedsDisplay()
//        })
//    } else {
//        cell.circleImageView.image = nil
//    }
    
    if let imageUrl = item.valueForKey("imageUrl") as? String {
        cell.circleButton.sd_setImageWithURL(NSURL(string: s3Url(imageUrl)), forState: UIControlState.Normal)
    }
    cell.circleButton.layer.cornerRadius = 41.75
    cell.circleButton.layer.masksToBounds = true
    
    if item.valueForKey("recordIDName") == nil {
        cell.recordIDName = nil
    } else {
        cell.recordIDName = item.valueForKey("recordIDName") as! String
    }
    cell.accessoryType = editableCells ? .DisclosureIndicator : .None
//    cell.userInteractionEnabled = editableCells
    
    return cell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return editableCells
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  //MARK: - NSFetchedResultsControllerDelegate
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    if tableView != nil {
        tableView.beginUpdates()
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    case .Delete:
      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
      break
    default:
      break
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    if self.tableView == nil {
        return
    }
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Update:
      tableView.reloadRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    }
    
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    dispatch_async(dispatch_get_main_queue()) {
        if self.tableView != nil {
            self.tableView.endUpdates()
        }
        NSNotificationCenter.defaultCenter().postNotificationName("refreshProfileVCData", object: nil)
    }
  }
    //MARK: - UICollectionViewDataSource methods
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let nib = UINib(nibName: "PeruseItemCollectionViewCell", bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.ReuseIdentifiers.CollectionViewCell)
        let cell = (collectionView.dequeueReusableCellWithReuseIdentifier(Constants.ReuseIdentifiers.CollectionViewCell, forIndexPath: indexPath) as! PeruseItemCollectionViewCell)

        let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        cell.item = item
        cell.delegate = itemDelegate
        cell.itemFavorited = true
        cell.setNeedsDisplay()
        return cell
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
}
