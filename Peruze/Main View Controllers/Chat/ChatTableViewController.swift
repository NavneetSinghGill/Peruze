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

class ChatTableViewController: UIViewController, UITableViewDelegate, ChatDeletionDelegate, showChatItemDetailDelegate {
  private struct Constants {
    static let SegueIdentifier = "toChat"
    static let TableViewRowHeight: CGFloat = 100
  }
  
  private lazy var dataSource = ChatTableViewDataSource()
  private var refreshControl: UIRefreshControl!
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.tableView = tableView
        self.tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.rowHeight = Constants.TableViewRowHeight
        self.dataSource.showChatItemDelegate = self
    }
  }
  @IBOutlet weak var noChatsLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var timer: NSTimer? = nil
    
  //MARK: - Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "getLocalAcceptedExchanges", name: NotificationCenterKeys.LNRefreshChatScreenForUpdatedExchanges, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "showChatScreen:", name: NotificationCenterKeys.LNAcceptedRequest, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "getLocalAcceptedExchangesAndSetRead:", name: "NewChat", object: nil)
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
    self.dataSource.tableView.reloadData()
//    checkForEmptyData(false)
    if self.dataSource.getLocalAcceptedExchanges() == 0 {
        self.noChatsLabel.hidden = false
        self.noChatsLabel.alpha = 1.0
    } else {
        self.noChatsLabel.hidden = true
        self.noChatsLabel.alpha = 0.0
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
  }
  
  //MARK: - UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    tableView.deselectRowAtIndexPath(indexPath, animated: false)
    let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath) as? ChatTableViewCell
    if cell!.itemImage.lesserImage!.image == nil || cell!.itemImage.prominentImage!.image == nil {
        return
    }
    performSegueWithIdentifier(Constants.SegueIdentifier, sender: cell)
  }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 116
    }
    
    //MARK: Refresh methods
    
    func endRefreshControl() {
        self.refreshControl.endRefreshing()
    }
    
    func refreshWithoutActivityIndicator() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        activityIndicatorView.alpha = 0
        self.noChatsLabel.alpha = 0
        refresh()
    }
    
    func refresh() {
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        logw("ChatTableview getAllChats")
        if self.timer != nil {
            self.timer!.invalidate()
        }
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "endRefreshControl", userInfo: nil, repeats: false)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let chatOp = GetChatsOperation(database: publicDB, context: managedConcurrentObjectContext) {
        dispatch_async(dispatch_get_main_queue()) {
        logw("ChatTableview getAllChats completion block")
        self.refreshControl.endRefreshing()
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.alpha = 1
        self.getLocalAcceptedExchanges()
        self.tableView.reloadData()
        self.timer = nil
      }
    }
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) GetChatsOperation added.")
    OperationQueue().addOperation(chatOp)
    activityIndicatorView.startAnimating()
  }
    
    func getLocalAcceptedExchanges() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if self.dataSource.getLocalAcceptedExchanges() == 0 {
            self.noChatsLabel.hidden = false
            self.noChatsLabel.alpha = 1.0
        } else {
            self.noChatsLabel.hidden = true
            self.noChatsLabel.alpha = 0.0
        }
    }
    
    func getLocalAcceptedExchangesAndSetRead(notification: NSNotification) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if notification.userInfo != nil {
            let userInfo: NSDictionary = notification.userInfo!
            let exchangeRecordIDName = userInfo.valueForKey("exchangeRecordIDName") as! String
            let context = NSManagedObjectContext.MR_context()
            let exchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: exchangeRecordIDName, inContext: context)
            if self.navigationController?.childViewControllers.count == 1 {
                exchange.setValue(false, forKey: "isRead")
                context.MR_saveToPersistentStoreAndWait()
                getLocalAcceptedExchanges()
                return
            }
            if let chatCollectionContainerVC = self.navigationController?.childViewControllers[1] as? ChatCollectionContainerViewController {
                exchange.setValue(true, forKey: "isRead")
                context.MR_saveToPersistentStoreAndWait()
                getLocalAcceptedExchanges()
            }
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
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
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
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) Accepted exchange Cancel completion block")
        dispatch_async(dispatch_get_main_queue()) {
          do{
            try self.dataSource.fetchedResultsController.performFetch()
            self.tableView.reloadData()
            self.getLocalAcceptedExchanges()
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
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
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
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) Accepted exchange Complete completion block.")
        dispatch_async(dispatch_get_main_queue()) {
          do{
            try self.dataSource.fetchedResultsController.performFetch()
            self.tableView.reloadData()
            self.getLocalAcceptedExchanges()
          } catch {
            logw("Fetch threw an error. Not updating")
            logw("\(error)")
          }
          self.activityIndicatorView.stopAnimating()
        }
      }
      
        //add operation to the queue
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) UpdateExchange with exchange status Completed, added to operation queue.")
        self.activityIndicatorView.startAnimating()
      OperationQueue().addOperation(operation)
    }
    accept.backgroundColor = .greenColor()
    return accept
  }
  
  //MARK: - ChatDeletionDelgate Methods
    func cancelExchange(exchange: NSManagedObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
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
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) UpdateExchange with exchange status: Cancelled added to Operation queue")
    self.activityIndicatorView.startAnimating()
    OperationQueue().addOperation(operation)
    
  }
  
    func completeExchange(exchange: NSManagedObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
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
  
    //MARK: - Show item detail
    
    func showItem(item: NSManagedObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) item: \(item)")
      let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("showItemDetailIdentifier")
        if let chatItemDetailShowDetailVC = navigationController?.childViewControllers[0] as? ChatItemDetailShowDetailViewController {
            chatItemDetailShowDetailVC.manageObjectItems = [item]
        }
        self.presentViewController(navigationController!, animated: true, completion: nil)
    }
    
  //MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with destVC: \(segue.destinationViewController)")
    guard
      let cell = sender as? ChatTableViewCell,
      let destVC = segue.destinationViewController as? ChatCollectionContainerViewController
      else {
        return
    }
    
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
    
    if me.valueForKey("recordIDName") as! String != cell.data?.valueForKey("itemOffered")!.valueForKey("owner")!.valueForKey("recordIDName") as! String {
        destVC.title = cell.data?.valueForKey("itemOffered")!.valueForKey("title") as! String
    } else {
        destVC.title = cell.data?.valueForKey("itemRequested")!.valueForKey("title") as! String
    }
    if cell.itemImage.prominentImage == nil || cell.itemImage.lesserImage == nil {
        return
    }
    destVC.prominentImage = cell.itemImage.prominentImage!
    destVC.lesserImage = cell.itemImage.lesserImage!
    destVC.theirItemName = cell.theirItemNameLabel.text
    destVC.yourItemName = cell.yourItemNameLabel.text
    destVC.exchange = cell.data
    destVC.senderId = me.valueForKey("recordIDName") as! String
    destVC.senderDisplayName =  me.valueForKey("firstName") as! String
    destVC.delegate = self
    destVC.showChatItemDelegate = self.dataSource.showChatItemDelegate
  }
  
    func showChatScreen(notification: NSNotification) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if notification.userInfo != nil {
            let userDict: NSDictionary = notification.userInfo!
            let exchangeRecordIDName = userDict.valueForKey("exchangeRecordIDName")
            let exchange = Exchange.MR_findFirstByAttribute("recordIDName", withValue: exchangeRecordIDName)
            
            let cell = tableView.dequeueReusableCellWithIdentifier("chat", forIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as? ChatTableViewCell
            cell!.theirItemNameLabel.text = exchange.valueForKey("itemOffered")!.valueForKey("title") as? String
            cell!.data = exchange
            performSegueWithIdentifier(Constants.SegueIdentifier, sender: cell)
        }
    }
}
