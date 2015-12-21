//
//  ChatTableViewDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/19/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ChatTableViewDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
  private struct Constants {
    static let ReuseIdentifier = "chat"
    static let NibName = "ChatTableViewCell"
    
  }
  var fetchedResultsController: NSFetchedResultsController!
  var tableView: UITableView!
  
  //MARK: - Lifecycle Methods
  override init() {
    super.init()
    getLocalAcceptedExchanges()
  }
    
    func getLocalAcceptedExchanges() {
        let chatPredicate = NSPredicate(format: "status = %@", NSNumber(integer: ExchangeStatus.Accepted.rawValue))
        fetchedResultsController = Exchange.MR_fetchAllSortedBy("date",
            ascending: true,
            withPredicate: chatPredicate,
            groupBy: nil,
            delegate: self)
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            logw("\(error)")
        }
    }
    
  
  //MARK: - UITableViewDataSource Methods
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
    tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as? ChatTableViewCell
    cell!.data = (fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
    
    return cell!
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    /* keep this empty */
  }
  
  //MARK: - NSFetchedResultsControllerDelegate
  
  private func errorCell() -> ChatTableViewCell {
    let returnCell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier) as! ChatTableViewCell
    
    return returnCell
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView.beginUpdates()
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
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Delete:
      tableView.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Update:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
      break
    }
  }
  
  //Swift 2.0
  //  func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
  //    switch type {
  //    case .Insert:
  //      tableView.insertRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Delete:
  //      tableView.deleteRowsAtIndexPaths([(indexPath ?? newIndexPath!)], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Update:
  //      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    case .Move:
  //      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
  //      break
  //    }
  //  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    tableView.endUpdates()
  }
}

