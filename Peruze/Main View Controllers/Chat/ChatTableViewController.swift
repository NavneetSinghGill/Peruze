//
//  ChatTableViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import CloudKit

class ChatTableViewController: UIViewController, UITableViewDelegate, ChatDeletionDelegate {
  private struct Constants {
    static let SegueIdentifier = "toChat"
  }
  
  private let dataSource = ChatTableViewDataSource()
  private var refreshControl: UIRefreshControl!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var noChatsLabel: UILabel!
  
  //MARK: - Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
    tableView.insertSubview(refreshControl, atIndex: 0)
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
    checkForEmptyData(false)
  }
  
  //MARK: - UITableViewDelegate Methods
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath)
    performSegueWithIdentifier(Constants.SegueIdentifier, sender: cell)
  }
  func refresh() {
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    let chatOp = GetChatsOperation(database: publicDB, context: managedConcurrentObjectContext) {
      dispatch_async(dispatch_get_main_queue()) {
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
      }
    }
    OperationQueue().addOperation(chatOp)
  }
  //MARK: Editing
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    return UITableViewCellEditingStyle.Delete
  }
  
  func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let normal = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Complete") { (rowAction, indexPath) -> Void in
      //self.dataSource.chats.removeAtIndex(indexPath.item)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
      //self.checkForEmptyData(true)
    }
    normal.backgroundColor = .greenColor()
    let defaultAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Cancel") { (rowAction, indexPath) -> Void in
      //self.dataSource.chats.removeAtIndex(indexPath.item)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
      //self.checkForEmptyData(true)
    }
    return [normal, defaultAction]
  }
  
  //MARK: - ChatDeletionDelgate Methods
  func cancelExchange(exchange: Exchange) {
    //TODO: Complete this
  }
  
  func completeExchange(exchange: Exchange) {
    //TODO: Complete This
  }
  private func checkForEmptyData(animated: Bool) {
    //        if tableView.visibleCells.count == 0 {
    //            UIView.animateWithDuration(animated ? 0.5 : 0.0) {
    //                self.noChatsLabel.alpha = 1.0
    //                self.tableView.alpha = 0.0
    //
    //            }
    //        }
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
    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedMainObjectContext)
    destVC.exchange = cell.data
    destVC.senderId = me.valueForKey("recordIDName") as! String
    destVC.senderDisplayName =  me.valueForKey("firstName") as! String
    destVC.delegate = self
  }
  
  
}
