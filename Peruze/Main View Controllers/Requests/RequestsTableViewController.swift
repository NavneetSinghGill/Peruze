//
//  RequestsTableViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 7/5/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

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
  @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var noRequetsLabel: UILabel!
  private struct Constants {
    static let TableViewRowHeight: CGFloat = 100
    static let CollectionViewSegueIdentifier = "toRequestCollectionView"
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: "refreshWithoutActivityIndicator", forControlEvents: UIControlEvents.ValueChanged)
    tableView.insertSubview(refreshControl!, atIndex: 0)
    title = "Requests"
    navigationController?.navigationBar.tintColor = .redColor()
    view.backgroundColor = .whiteColor()
    refresh()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "localRefresh", name: "getRequestedExchange", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "localRefresh", name: NotificationCenterKeys.LNRefreshRequestScreenWithLocalData, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh", name: "oneTimeFetch", object: nil)
  }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        localRefresh()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        resetBadgeCounter()
        if NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") != nil && NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") as! String == "no"{
            refresh()
            NSUserDefaults.standardUserDefaults().setValue("yes", forKey: "isRequestsShowing")
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "getRequestedExchange", object: nil)
    }
    
    func refreshWithoutActivityIndicator() {
         self.activityIndicatorView.alpha = 0
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            self.refreshControl!.endRefreshing()
            return
        }
        self.refresh()
    }
    
    func refresh() {
     //reload the data
    self.noRequetsLabel.alpha = 0
    self.noRequetsLabel.hidden = true
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
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.alpha = 1
        try self.dataSource.fetchedResultsController.performFetch()
        self.tableView.reloadData()
      } catch {
           logw("RequestsTableViewController iCloud data fetch failed with error: \(error)")
      }
      dispatch_async(dispatch_get_main_queue()){
        self.tableView.reloadData()
        if self.tableView.numberOfRowsInSection(0) > 0 {
            self.noRequetsLabel.alpha = 0
            self.noRequetsLabel.hidden = true
        } else {
            self.noRequetsLabel.alpha = 1
            self.noRequetsLabel.hidden = false
        }
        self.refreshControl?.endRefreshing()
      }
    }

    fetchMissingItems.addDependency(fetchExchanges)
    fetchMissingPeople.addDependency(fetchMissingItems)
    updateExchanges.addDependency(fetchMissingPeople)
    
    logw("RequestsTableViewController iCloud Data fetch initiated.")
    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = NSQualityOfService.Utility
    operationQueue.addOperations([fetchExchanges, fetchMissingItems, fetchMissingPeople, updateExchanges], waitUntilFinished: false)
    self.activityIndicatorView.startAnimating()
  }
    
    func localRefresh() {
         do {
            logw("RequestsTableViewController fetching local requests.")
            self.activityIndicatorView.stopAnimating()
            self.activityIndicatorView.alpha = 1
            try self.dataSource.fetchedResultsController.performFetch()
            dispatch_async(dispatch_get_main_queue()){
                self.tableView.reloadData()
                if self.dataSource.fetchedResultsController.sections?[0].numberOfObjects > 0 {
                    self.noRequetsLabel.alpha = 0
                    self.noRequetsLabel.hidden = true
                } else {
                    self.noRequetsLabel.alpha = 1
                    self.noRequetsLabel.hidden = false
                }
                self.refreshControl?.endRefreshing()
            }
        } catch {
            logw("RequestsTableViewController fetch local result failed with error: \(error)")
        }
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
    checkForEmptyData(true)
  }
  
//  private func checkForEmptyData(animated: Bool) {
//    if tableView.visibleCells.count == 0 {
//      UIView.animateWithDuration(animated ? 0.5 : 0.0) {
//        self.titleLabel.alpha = 1.0
//        self.tableView.alpha = 0.0
//      }
//    }
//  }
    private func checkForEmptyData(animated: Bool) {
        if self.activityIndicatorView.isAnimating() {
            self.noRequetsLabel.alpha = 0
            self.noRequetsLabel.hidden = true
            return
        }
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) number of requests: \(dataSource.fetchedResultsController?.sections?[0].numberOfObjects)")
        if dataSource.fetchedResultsController?.sections?[0].numberOfObjects == 0 {
            UIView.animateWithDuration(animated ? 0.5 : 0.0) {
                self.noRequetsLabel.alpha = 1.0
                self.noRequetsLabel.hidden = false
//                self.tableView.alpha = 0.2
            }
        } else {
            UIView.animateWithDuration(animated ? 0.5 : 0.0) {
                self.noRequetsLabel.alpha = 0.0
                self.noRequetsLabel.hidden = true
                self.tableView.alpha = 1.0
            }
        }
    }
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier(Constants.CollectionViewSegueIdentifier, sender: indexPath)
    logw("Requests Table cell tapped of indexpath: \(indexPath)")
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let deny = denyEditAction()
    let accept = acceptEditAction()
    return [deny, accept]
  }
  
  private func denyEditAction() -> UITableViewRowAction {
    return UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Deny") { (rowAction, indexPath) -> Void in
      logw("Requests Table cell Deny tapped.")
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
      self.denyExchangeAtIndexPath(indexPath)
    }
  }
  
    func denyExchangeAtIndexPath(indexPath: NSIndexPath,completionBlock: (Void -> Void) = {}) {
        //get the recordIDName for the exchange at that index path
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as! String
        
        //create the operation
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        let operation = UpdateExchangeWithIncrementalData(
            recordIDName: idName,
            exchangeStatus: ExchangeStatus.Denied,
            database: publicDB,
            context: NSManagedObjectContext.MR_context(),
            errorBlock: {
                let alertController = UIAlertController(title: "Peruze", message: "An error occured while Denying exchange.", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                alertController.addAction(defaultAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
                let localExchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: idName, inContext: managedConcurrentObjectContext)
                localExchange.setValue(0, forKey: "status")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        })
        //add completion
        operation.completionBlock = {
            logw("RequestsTableViewController denyEditAction completion block.")
            dispatch_async(dispatch_get_main_queue()) {
                do {
                    try self.dataSource.fetchedResultsController.performFetch()
                    //            let item = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath)
                    //            let itemOfferedOwner = item.valueForKey("owner")
                    //            let me = Person.MR_findFirstByAttribute("me", withValue: true)
                    //            if itemOfferedOwner!.valueForKey("recordIDName") as! String != me.valueForKey("recordIDName") as! String && itemOfferedOwner!.valueForKey("recordIDName") as! String != "__defaultOwner__" {
                    //
                    //                let predicate = NSPredicate(format: "itemOffered.recordIDName == %@ OR itemRequested.recordIDName == %@",item.valueForKey("recordIDName") as! String, item.valueForKey("recordIDName") as! String)
                    //                let exchanges = Exchange.MR_findAllWithPredicate(predicate)
                    //                if exchanges.count <= 1 {
                    //                    item.setValue("no", forKey: "hasRequested")
                    //                }
                    //            }
                    self.localRefresh()
                    completionBlock()
                } catch {
                    logw("RequestTableViewController UpdateExchangeWithIncrementalData ExchangeStatus.Denied completion block fetch local data failed with error: \(error)")
                }
                self.tableView.reloadData()
                self.activityIndicatorView.stopAnimating()
            }
        }
        
        //add operation to the queue
        self.activityIndicatorView.startAnimating()
        OperationQueue().addOperation(operation)
    }
    
  private func acceptEditAction() -> UITableViewRowAction {
    let accept = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Accept") { (rowAction, indexPath) -> Void in
      logw("Requests Table cell Accept tapped.")
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
      self.acceptExchangeAtIndexPath(indexPath)
    }
    accept.backgroundColor = .greenColor()
    return accept
  }
  
    func acceptExchangeAtIndexPath(indexPath: NSIndexPath,completionBlock: (Void -> Void) = {}) {
        //get the recordIDName for the exchange at that index path
        if !NetworkConnection.connectedToNetwork() {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        let idName = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath).valueForKey("recordIDName") as! String
        
        //create the operation
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        let operation = UpdateExchangeWithIncrementalData(
            recordIDName: idName,
            exchangeStatus: ExchangeStatus.Accepted,
            database: publicDB,
            context: managedConcurrentObjectContext,
            errorBlock: {
                let alertController = UIAlertController(title: "Peruze", message: "An error occured while Accepting exchange.", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                alertController.addAction(defaultAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
                let localExchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: idName, inContext: managedConcurrentObjectContext)
                localExchange.setValue(0, forKey: "status")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        })
        
        //add completion
        operation.completionBlock = { () -> Void in
            logw("RequestsTableViewController acceptEditAction completion block.")
            dispatch_async(dispatch_get_main_queue()) {
                do {
                    //            try self.dataSource.fetchedResultsController.performFetch()
                    self.localRefresh()
                } catch {
                    logw("RequestTableViewController UpdateExchangeWithIncrementalData ExchangeStatus.Accepted completion block fetch local data failed with error: \(error)")
                }
                self.tableView.reloadData()
                self.activityIndicatorView.stopAnimating()
                NSNotificationCenter.defaultCenter().postNotificationName("AcceptedRequest", object: nil, userInfo: ["exchangeRecordIDName": idName])
            }
        }
        
        //add operation to the queue
        self.activityIndicatorView.startAnimating()
        OperationQueue().addOperation(operation)
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
        logw("Requests Table segue")
        destVC.indexPathToScrollToOnInit = indexPath
        destVC.dataSource = dataSource
        destVC.parentVC = self
      }
    }
  }
    
    //MARK: - reset cloudkit badge value
    func resetBadgeCounter() {
        NSNotificationCenter.defaultCenter().postNotificationName("ResetBadgeValue", object:nil)
    }
  
}
