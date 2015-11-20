//
//  RequestsTableViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 7/5/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

class RequestsTableViewController: UIViewController, UITableViewDelegate, RequestCollectionViewCellDelegate {
  let dataSource = RequestsDataSource()
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.requestDelegate = self
      dataSource.tableView = tableView
      tableView.dataSource = dataSource
      tableView.delegate = self
      tableView.rowHeight = Constants.TableViewRowHeight
    }
  }
  var refreshControl: UIRefreshControl?
  var titleLabel = UILabel()
  private struct Constants {
    static let TableViewRowHeight: CGFloat = 100
    static let CollectionViewSegueIdentifier = "toRequestCollectionView"
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
    tableView.insertSubview(refreshControl!, atIndex: 0)
    title = "Requests"
    navigationController?.navigationBar.tintColor = .redColor()
    view.backgroundColor = .whiteColor()
  }
  func refresh() {
    //reload the data
    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let myRecordIDName = me.valueForKey("recordIDName") as! String
    let fetchExchanges = GetOnlyRequestedExchangesOperation(
      personRecordIDName: myRecordIDName,
      status: ExchangeStatus.Pending,
      database: publicDB,
      context: managedConcurrentObjectContext
    )
    let fetchMissingItems = GetAllItemsWithMissingDataOperation(database: publicDB)
    let fetchMissingPeople = GetAllPersonsWithMissingData(database: publicDB)
    let updateExchanges = UpdateAllExchangesOperation(database: publicDB)
    updateExchanges.completionBlock = {
      do {
        try self.dataSource.fetchedResultsController.performFetch()
      } catch {
           print(error)
        
      }
      dispatch_async(dispatch_get_main_queue()){
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
      }
    }

    fetchMissingItems.addDependency(fetchExchanges)
    fetchMissingPeople.addDependency(fetchMissingItems)
    updateExchanges.addDependency(fetchMissingPeople)
    
    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = NSQualityOfService.Utility
    operationQueue.addOperations([fetchExchanges, fetchMissingItems, fetchMissingPeople, updateExchanges], waitUntilFinished: false)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    titleLabel.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
    titleLabel.alpha = 0.0
    titleLabel.text = "No More Requests"
    titleLabel.textAlignment = NSTextAlignment.Center
    titleLabel.font = .preferredFontForTextStyle(UIFontTextStyleBody)
    titleLabel.textColor = .lightGrayColor()
    view.addSubview(titleLabel)
  }
  
  private func checkForEmptyData(animated: Bool) {
    if tableView.visibleCells.count == 0 {
      UIView.animateWithDuration(animated ? 0.5 : 0.0) {
        self.titleLabel.alpha = 1.0
        self.tableView.alpha = 0.0
      }
    }
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier(Constants.CollectionViewSegueIdentifier, sender: indexPath)
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let deny = denyEditAction()
    let accept = acceptEditAction()
    return [deny, accept]
  }
  
  private func denyEditAction() -> UITableViewRowAction {
    return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Deny") { (rowAction, indexPath) -> Void in
      
      //get the recordIDName for the exchange at that index path
      let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as! String
      
      //create the operation
      let publicDB = CKContainer.defaultContainer().publicCloudDatabase
      let operation = UpdateExchangeWithIncrementalData(
        recordIDName: idName,
        exchangeStatus: ExchangeStatus.Denied,
        database: publicDB,
        context: managedConcurrentObjectContext)
      //add completion
      operation.completionBlock = {
        dispatch_async(dispatch_get_main_queue()) {
          do {
            try self.dataSource.fetchedResultsController.performFetch()
          } catch {
            print(error)
          }
          self.tableView.reloadData()
        }
      }
      
      //add operation to the queue
      OperationQueue().addOperation(operation)
    }
  }
  
  private func acceptEditAction() -> UITableViewRowAction {
    let accept = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Accept") { (rowAction, indexPath) -> Void in
      
      //get the recordIDName for the exchange at that index path
      let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as! String
      
      //create the operation
      let publicDB = CKContainer.defaultContainer().publicCloudDatabase
      let operation = UpdateExchangeWithIncrementalData(
        recordIDName: idName,
        exchangeStatus: ExchangeStatus.Accepted,
        database: publicDB,
        context: managedConcurrentObjectContext)
      
      //add completion
      operation.completionBlock = { () -> Void in
        dispatch_async(dispatch_get_main_queue()) {
          do {
            try self.dataSource.fetchedResultsController.performFetch()
          } catch {
            print(error)
          }
          self.tableView.reloadData()
        }
      }
      
      //add operation to the queue
      OperationQueue().addOperation(operation)
    }
    accept.backgroundColor = .greenColor()
    return accept
  }
  
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    return UITableViewCellEditingStyle.Delete
  }
  func requestAccepted(request: Exchange) {
    dataSource.deleteItemAtIndex(0)
  }
  
  func requestDenied(request: Exchange) {
    dataSource.deleteItemAtIndex(0)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let indexPath = sender as? NSIndexPath {
      if let destVC = segue.destinationViewController as? RequestsViewController {
        destVC.indexPathToScrollToOnInit = indexPath
        destVC.dataSource = dataSource
      }
    }
  }
  
}
