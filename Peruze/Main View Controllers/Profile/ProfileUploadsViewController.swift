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
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData:", name: "FetchedPersonUploads", object: nil)
  }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.dataSource.fetchAndReloadLocalContent() == 0 {
            self.titleLabel.hidden = false
        } else {
            self.titleLabel.hidden = true
        }
    }
    
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.reloadData()
  }
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: false)
    let uploadView = storyboard!.instantiateViewControllerWithIdentifier(Constants.UploadViewControllerIdentifier) as! UploadViewController
    let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath) as! ProfileUploadsTableViewCell
    if cell.circleImageView.image != nil {
        uploadView.image = cell.circleImageView.image
        uploadView.itemTitle = cell.titleTextLabel.text
        uploadView.itemDescription = cell.descriptionTextLabel.text
        uploadView.recordIDName = cell.recordIDName
        presentViewController(uploadView, animated: true) {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
            self.tableView.reloadData()
        }
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
        let saveOwner = item.valueForKey("owner")
        item.setValue(nil, forKey: "owner")
        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        if let parentVC = self.parentViewController?.parentViewController as? ProfileViewController {
            parentVC.updateViewAfterGettingResponse()
        }
        self.dataSource.fetchAndReloadLocalContent()
        self.tableView.reloadData()
        logw("OperationQueue().addOperation(DeleteItemOperation)")
        let completionHandler = { dispatch_async(dispatch_get_main_queue()) {
            if let parentVC = self.parentViewController?.parentViewController as? ProfileViewController{
                do {
                    logw("Manual deletion of item after item updation success")
                    let localItem = try managedConcurrentObjectContext.existingObjectWithID(item.objectID)
                    managedConcurrentObjectContext.deleteObject(localItem)
                    managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                    parentVC.updateViewAfterGettingResponse()
                    try self.dataSource.fetchedResultsController.performFetch()
                    dispatch_async(dispatch_get_main_queue()){
                        if self.tableView != nil {
                            self.tableView.reloadData()
                        }
                    }
                } catch {
                    logw("Error while deleting local item in item updation completion block: \(error)")
                }
            }} }
        let errorCompletionHandler = { dispatch_async(dispatch_get_main_queue()) {
            if let parentVC = self.parentViewController?.parentViewController as? ProfileViewController{
                item.setValue(saveOwner, forKey: "owner")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                parentVC.updateViewAfterGettingResponse()
                
                let alertController = UIAlertController(title: "Peruze", message: "An error occured while Deleting item.", preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                alertController.addAction(defaultAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }} }
//        OperationQueue().addOperation(
//            DeleteItemOperation(
//                recordIDName: item.valueForKey("recordIDName") as? String,
//                presentationContext: self,
//                completionHandler: completionHandler,
//                errorCompletionHandler: errorCompletionHandler))
        OperationQueue().addOperation(
            PostItemOperation(
                image: UIImage(data: (item.valueForKey("image") as? NSData!)!)!,
                title: (item.valueForKey("title") as? String)!,
                detail: (item.valueForKey("detail") as? String)!,
                recordIDName: item.valueForKey("recordIDName") as? String,
                imageUrl: (item.valueForKey("imageUrl") as? String)!,
                isDelete: 1,
                presentationContext: self,
                completionHandler: completionHandler,
                errorCompletionHandler: errorCompletionHandler
            )
        )
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
