//
//  ProfileUploadsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileUploadsViewController: UIViewController, UITableViewDelegate {
  private struct Constants {
    static let TableViewCellHeight: CGFloat = 100
    static let UploadViewControllerIdentifier = "UploadViewController"
  }
  
  @IBOutlet weak var titleLabel: UILabel!
  let dataSource = ProfileUploadsDataSource()
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.tableView = tableView
      dataSource.editableCells = tabBarController?.parentViewController?.tabBarController != nil
      tableView.dataSource = dataSource
      tableView.delegate = self
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel.alpha = 0.0
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData:", name: "FetchedPersonUploads", object: nil)
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.reloadData()
  }
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let uploadView = storyboard!.instantiateViewControllerWithIdentifier(Constants.UploadViewControllerIdentifier) as! UploadViewController
    let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath) as! ProfileUploadsTableViewCell
    uploadView.image = cell.circleImageView.image
    uploadView.itemTitle = cell.titleTextLabel.text
    uploadView.itemDescription = cell.descriptionTextLabel.text
    uploadView.recordIDName = cell.recordIDName
    presentViewController(uploadView, animated: true) {
      self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
      self.tableView.reloadData()
    }
  }
  
  //MARK: Editing
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    return .Delete
  }
  
  func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let defaultAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { (rowAction, indexPath) -> Void in
      
      //self.dataSource.items.removeAtIndex(indexPath.row)
//      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        let item = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        logw("OperationQueue().addOperation(DeleteItemOperation)")
        let allCompletionHandlers = { dispatch_async(dispatch_get_main_queue()) {
            if let parentVC = self.parentViewController?.parentViewController as? ProfileViewController{
                parentVC.updateViewAfterGettingResponse()
            }} }
        OperationQueue().addOperation(
            DeleteItemOperation(
                recordIDName: item.valueForKey("recordIDName") as? String,
                presentationContext: self,
                completionHandler: allCompletionHandlers,
                errorCompletionHandler: allCompletionHandlers))
    }
    return [defaultAction]
  }
    
    
    //MARK: Reloading view on fetch data from server
    func reloadFetchedData (notification : NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.dataSource.personRecordID = notification.object as! String;
        })
    }
}
