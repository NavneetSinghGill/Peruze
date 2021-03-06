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
        cell.itemFavorited = self.uploadsIDs.filter{ $0 == (item.valueForKey("recordIDName") as! String) }.count != 0
        cell.ownerProfileImage.userInteractionEnabled = false
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
    var presentationContext: UIViewController!
  //TODO: Get items
  var tableView: UITableView!
  var fetchedResultsController: NSFetchedResultsController!
  var currentlyTappedUploadedItem: NSManagedObject?
  var itemDelegate: PeruseItemCollectionViewCellDelegate?
  var personRecordID: String! {
    didSet {
      if personRecordID == nil { return }
        if self.fetchAndReloadLocalContent() == 0{
            if let uploadController = self.presentationContext as? ProfileUploadsViewController {
                uploadController.titleLabel.hidden = false
            }
        } else {
            if let uploadController = self.presentationContext as? ProfileUploadsViewController {
                uploadController.titleLabel.hidden = true
            }
        }
        if tableView != nil {
            tableView.reloadData()
        }
    }
  }
    var uploadsIDs = [String]()
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
        let predicateForDeletedItem = NSPredicate(format: "isDelete != 1 AND title != nil AND imageUrl != nil")
        fetchedResultsController = Item.MR_fetchAllSortedBy("title",
            ascending: true,
            withPredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicateForDeletedItem]),
            groupBy: nil, delegate: self,
            inContext: managedConcurrentObjectContext)
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.sections![0].objects != nil {
                self.uploadsIDs = [String]()
                var trueFavoriteUploadIDs = [String]()
                self.uploadsIDs = fetchedResultsController.sections![0].objects!.map { $0.valueForKey("recordIDName") as! String }
                let favorites = getFavorites()
                for uploadID in self.uploadsIDs {
                    if favorites.contains(uploadID) {
                        trueFavoriteUploadIDs.append(uploadID)
                    }
                }
                self.uploadsIDs = trueFavoriteUploadIDs
            }
            dispatch_async(dispatch_get_main_queue()) {
                if self.tableView != nil {
                    self.tableView.reloadData()
                }
            }
        } catch {
            logw("ProfileUploads local data fetch failed with error: \(error)")
        }
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) number of uploads: \(fetchedResultsController.sections![0].numberOfObjects)")
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        if me.valueForKey("recordIDName") as! String == personRecordID {
            NSNotificationCenter.defaultCenter().postNotificationName("refreshProfileVCData", object: nil)
        }
        return fetchedResultsController.sections![0].numberOfObjects
    }
    
    func getFavorites() -> [String] {
         let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
        var trueFavorites = [NSManagedObject]()
        if let favorites = (me.valueForKey("favorites") as? NSSet)?.allObjects as? [NSManagedObject] {
            for favoriteObj in favorites {
                if favoriteObj.valueForKey("title") != nil && favoriteObj.valueForKey("isDelete") as! Int != 1  {
                    trueFavorites.append(favoriteObj)
                }
            }
            return trueFavorites.map { $0.valueForKey("recordIDName") as! String }
        } else {
            logw("me.valueForKey('favorites') was not an NSSet ")
        }
        return []
    }
    
  var editableCells = true
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
      forIndexPath: indexPath) as! ProfileUploadsTableViewCell
    
    let item = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
    if fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject == nil {
        return cell
    }
    if let title = item.valueForKey("title") as? String {
        cell.titleTextLabel.text = title
    } else {
        cell.titleTextLabel.text = ""
    }
//    cell.titleTextLabel.text = (item.valueForKey("title") as! String)
    cell.subtitleTextLabel.text = ""
    if let detail = item.valueForKey("detail") as? String {
        cell.descriptionTextLabel.text = detail
    } else {
        cell.descriptionTextLabel.text = ""
    }
//    cell.descriptionTextLabel.text = (item.valueForKey("detail") as! String)
    
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
//        self.tableView.reloadData()
//        tableView.beginUpdates()
    }
  }
//
//  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//    switch type {
//    case .Insert:
//      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
//      break
//    case .Delete:
//      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
//      break
//    default:
//      break
//    }
//  }
//  
//  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//    if self.tableView == nil {
//        return
//    }
//    if NSThread.isMainThread(){
//        switch type {
//        case .Insert:
//            tableView.insertRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            break
//        case .Delete:
//            tableView.deleteRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            break
//        case .Update:
//            tableView.reloadRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            break
//        case .Move:
//            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            break
//        }
//    } else {
//        dispatch_async(dispatch_get_main_queue()) {
//            switch type {
//            case .Insert:
//                self.tableView.insertRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//                break
//            case .Delete:
//                self.tableView.deleteRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//                break
//            case .Update:
//                self.tableView.reloadRowsAtIndexPaths([indexPath ?? newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//                break
//            case .Move:
//                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//                break
//            }
//        }
//    }
//    
//  }
//  
//  func controllerDidChangeContent(controller: NSFetchedResultsController) {
//    
//    if NSThread.isMainThread() {
//        if self.tableView != nil {
//            self.tableView.endUpdates()
//        }
//    } else {
//        dispatch_async(dispatch_get_main_queue()) {
//            if self.tableView != nil {
//                self.tableView.endUpdates()
//            }
//        }
//    }
//        NSNotificationCenter.defaultCenter().postNotificationName("refreshProfileVCData", object: nil)
//  }
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
