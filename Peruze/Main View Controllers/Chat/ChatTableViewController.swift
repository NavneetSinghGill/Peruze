//
//  ChatTableViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

class ChatTableViewController: UIViewController, UITableViewDelegate, ChatDeletionDelegate {
  private struct Constants {
    static let SegueIdentifier = "toChat"
  }
  
  private lazy var dataSource = ChatTableViewDataSource()
  private var refreshControl: UIRefreshControl!
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.tableView = tableView
    }
  }
  @IBOutlet weak var noChatsLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
  //MARK: - Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "getLocalAcceptedExchanges", name: NotificationCenterKeys.LNRefreshChatScreenForUpdatedExchanges, object: nil)
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refreshWithoutActivityIndicator", forControlEvents: UIControlEvents.ValueChanged)
    tableView.insertSubview(refreshControl, atIndex: 0)
    refresh()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    tableView.alpha = 1.0
    noChatsLabel.alpha = 0.0
    tableView.delegate = self
    tableView.dataSource = dataSource
    tableView.estimatedRowHeight = CGFloat(55)
    tableView.rowHeight = UITableViewAutomaticDimension
    navigationController!.navigationBar.tintColor = .redColor()
    tableView.reloadData()
    self.dataSource.getLocalAcceptedExchanges()
    checkForEmptyData(false)
  }
  
  //MARK: - UITableViewDelegate Methods
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    performSegueWithIdentifier(Constants.SegueIdentifier, sender: cell)
  }
    
    //MARK: Refresh methods
    
    func refreshWithoutActivityIndicator() {
        activityIndicatorView.alpha = 0
        self.noChatsLabel.alpha = 0
        refresh()
    }
    
  func refresh() {
    logw("ChatTableview getAllChats")
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let chatOp = GetChatsOperation(database: publicDB, context: managedConcurrentObjectContext) {
      dispatch_async(dispatch_get_main_queue()) {
        logw("ChatTableview getAllChats completion block")
        self.refreshControl.endRefreshing()
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.alpha = 1
        if self.dataSource.getLocalAcceptedExchanges() == 0 {
            self.noChatsLabel.alpha = 1
        } else {
            self.noChatsLabel.alpha = 0
        }
      }
    }
    OperationQueue().addOperation(chatOp)
    activityIndicatorView.startAnimating()
  }
    
    func getLocalAcceptedExchanges() {
        if self.dataSource.getLocalAcceptedExchanges() == 0 {
            self.noChatsLabel.alpha = 1.0
        } else {
            self.noChatsLabel.alpha = 0.0
        }
    }
    
  //MARK: Editing
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    return UITableViewCellEditingStyle.Delete
  }
  
  func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    return [cancelEditAction(), completeEditAction()]
  }
  
  private func cancelEditAction() -> UITableViewRowAction {
    return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Cancel") { (rowAction, indexPath) -> Void in
      logw("Accepted exchange Cancel tapped.")
      //Swift 2.0
      //get the recordIDName for the exchange at that index path
      guard let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as? String else {
        assertionFailure("fetched results controller did not return an object with a 'recordIDName'")
        return
      }
      
      //create the operation
      let publicDB = CKContainer.defaultContainer().publicCloudDatabase
      let operation = UpdateExchangeWithIncrementalData(
        recordIDName: idName,
        exchangeStatus: ExchangeStatus.Cancelled,
        database: publicDB,
        context: managedConcurrentObjectContext,
        errorBlock: {
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while Canceling exchange.", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
      })
      
      //add completion
      operation.completionBlock = { () -> Void in
        dispatch_async(dispatch_get_main_queue()) {
          do{
            try self.dataSource.fetchedResultsController.performFetch()
            self.tableView.reloadData()
          } catch {
            logw("Fetch threw an error. Not updating")
            logw("\(error)")
          }
          self.activityIndicatorView.stopAnimating()
        }
      }
      
      
      //add operation to the queue
        self.activityIndicatorView.startAnimating()
      OperationQueue().addOperation(operation)
    }
  }
  
  private func completeEditAction() -> UITableViewRowAction {
    let accept = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Complete") { (rowAction, indexPath) -> Void in
      logw("Accepted exchange Complete tapped.")
      //get the recordIDName for the exchange at that index path
      //Swift 2.0
      guard let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as? String else {
        assertionFailure("fetched results controller did not return an object with a 'recordIDName'")
        return
      }
      
      //create the operation
      let publicDB = CKContainer.defaultContainer().publicCloudDatabase
      let operation = UpdateExchangeWithIncrementalData(
        recordIDName: idName,
        exchangeStatus: ExchangeStatus.Completed,
        database: publicDB,
        context: managedConcurrentObjectContext,
        errorBlock: {
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while Completing exchange.", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
      })
      
      //add completion
      operation.completionBlock = {
        dispatch_async(dispatch_get_main_queue()) {
          do{
            try self.dataSource.fetchedResultsController.performFetch()
            self.tableView.reloadData()
          } catch {
            logw("Fetch threw an error. Not updating")
            logw("\(error)")
          }
          self.activityIndicatorView.stopAnimating()
        }
      }
      
      //add operation to the queue
        self.activityIndicatorView.startAnimating()
      OperationQueue().addOperation(operation)
    }
    accept.backgroundColor = .greenColor()
    return accept
  }
  
  //MARK: - ChatDeletionDelgate Methods
  func cancelExchange(exchange: NSManagedObject) {
    //get the recordIDName for the exchange at that index path
    //Swift 2.0
    guard let idName = exchange.valueForKey("recordIDName") as? String else {
      assertionFailure("fethed results controller did not return an object with a 'recordIDName'")
      return
    }
    
    //create the operation
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let operation = UpdateExchangeWithIncrementalData(
      recordIDName: idName,
      exchangeStatus: ExchangeStatus.Cancelled,
      database: publicDB,
        context: managedConcurrentObjectContext,
        errorBlock: {
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while Canceling exchange.", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
    })
    
    //add completion
    operation.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        self.tableView.reloadData()
        self.activityIndicatorView.stopAnimating()
      }
    }
    
    //add operation to the queue
    self.activityIndicatorView.startAnimating()
    OperationQueue().addOperation(operation)
    
  }
  
  func completeExchange(exchange: NSManagedObject) {
    //get the recordIDName for the exchange at that index path
    //Swift 2.0
    guard let idName = exchange.valueForKey("recordIDName") as? String else {
      assertionFailure("fethed results controller did not return an object with a 'recordIDName'")
      return
    }
    
    //create the operation
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let operation = UpdateExchangeWithIncrementalData(
      recordIDName: idName,
      exchangeStatus: ExchangeStatus.Completed,
      database: publicDB,
        context: managedConcurrentObjectContext,
        errorBlock: {
            let alertController = UIAlertController(title: "Peruze", message: "An error occured while Completing exchange.", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
    })
    
    //add completion
    operation.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        self.activityIndicatorView.stopAnimating()
        self.tableView.reloadData()
      }
    }
    
    //add operation to the queue
    self.activityIndicatorView.startAnimating()
    OperationQueue().addOperation(operation)
  }
  
  private func checkForEmptyData(animated: Bool) {
            if tableView.visibleCells.count == 0 {
                UIView.animateWithDuration(animated ? 0.5 : 0.0) {
                    self.noChatsLabel.alpha = 1.0
//                    self.tableView.alpha = 0.0
    
                }
            } else {
                self.noChatsLabel.alpha = 0.0
    }
  }
  
  //MARK: - Navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    guard
      let cell = sender as? ChatTableViewCell,
      let destVC = segue.destinationViewController as? ChatCollectionViewController
      else {
        return
    }
    
    destVC.title = cell.theirItemNameLabel.text
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    destVC.exchange = cell.data
    destVC.senderId = me.valueForKey("recordIDName") as! String
    destVC.senderDisplayName =  me.valueForKey("firstName") as! String
    destVC.delegate = self
  }
  
  
}
