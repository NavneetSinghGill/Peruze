//
//  ProfileUploadsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileUploadsDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  
  private struct Constants {
    static let ReuseIdentifier = "ProfileUpload"
    static let NibName = "ProfileUploadsTableViewCell"
  }
  
  //TODO: Get items
  var tableView: UITableView!
  var fetchedResultsController: NSFetchedResultsController!
  var personRecordID: String! {
    didSet {
      if personRecordID == nil { return }
      self.fetchAndReloadLocalContent()
        if tableView != nil {
            tableView.reloadData()
        }
    }
  }
  
  override init() {
    super.init()
    if personRecordID == nil {
      return
    }
    fetchAndReloadLocalContent()
  }
    
    func fetchAndReloadLocalContent() -> Int {
        if personRecordID == nil { return 0}
        let predicate = NSPredicate(format: "owner.recordIDName = %@", personRecordID)
        let predicateForDeletedItem = NSPredicate(format: "isDelete != 1")
//        let predicateForDeletedItem = NSPredicate(value: true)
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
    if item.valueForKey("imageUrl") != nil {
        if item.valueForKey("image") != nil {
           cell.circleImageView.image = UIImage(data:(item.valueForKey("image") as! NSData))
        } else {
            cell.circleImageView.image = nil
        }
    } else {
        cell.circleImageView.image = nil
    }
    if item.valueForKey("recordIDName") == nil {
        cell.recordIDName = nil
    } else {
        cell.recordIDName = item.valueForKey("recordIDName") as! String
    }
    cell.accessoryType = editableCells ? .DisclosureIndicator : .None
    cell.userInteractionEnabled = editableCells
    
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
}
