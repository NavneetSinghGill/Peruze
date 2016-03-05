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
      dataSource.presentationContext = self
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData:", name: "FetchedPersonUploads", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadNewLocalData", name: "reloadPeruzeExchangeScreen", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(dataSource, selector: "fetchAndReloadLocalContent", name: "justReloadPeruseItemMainScreen", object: nil)
  }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.alpha = 1.0
        if self.dataSource.fetchAndReloadLocalContent() == 0 {
            self.titleLabel.hidden = false
        } else {
            self.titleLabel.hidden = true
        }
    }
    
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.dataSource.fetchAndReloadLocalContent()
    tableView.reloadData()
  }
    
    func reloadNewLocalData() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    var isThisMyProfile = true
    if let profileVC = self.parentViewController?.parentViewController as? ProfileViewController {
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        if me.valueForKey("recordIDName") as! String != profileVC.personForProfile?.valueForKey("recordIDName") as! String {
            isThisMyProfile = false
        }
    }
    if isThisMyProfile == true {
        let uploadView = storyboard!.instantiateViewControllerWithIdentifier(Constants.UploadViewControllerIdentifier) as! UploadViewController
        let cell = dataSource.tableView(tableView, cellForRowAtIndexPath: indexPath) as! ProfileUploadsTableViewCell
//        uploadView.image = cell.circleImageView.image
        if cell.circleButton.imageView?.image != nil {
            uploadView.image = cell.circleButton.imageView?.image
            uploadView.itemTitle = cell.titleTextLabel.text
            uploadView.itemDescription = cell.descriptionTextLabel.text
            uploadView.recordIDName = cell.recordIDName
            
            let item = Item.MR_findFirstByAttribute("recordIDName", withValue: cell.recordIDName)
            uploadView.imageUrl = item.valueForKey("imageUrl") as! String
            presentViewController(uploadView, animated: true) {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
                self.tableView.reloadData()
            }
        }
    } else {
        self.dataSource.currentlyTappedUploadedItem = self.dataSource.fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject
        if let parentVC = parentViewController as? ProfileContainerViewController {
            if let originVC = parentVC.parentViewController as? ProfileViewController {
//                self.indexOfSelectedTableViewRow = indexPath.row
                NSUserDefaults.standardUserDefaults().setInteger(indexPath.row, forKey: "UploadedItemIndex")
                NSUserDefaults.standardUserDefaults().synchronize()
                originVC.performSegueWithIdentifier("toUploadDetail", sender:dataSource)
            }
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
      
        if NetworkConnection.connectedToNetwork() {
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
                    image: UIImage(),
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
        } else {
            let alert = UIAlertController(title: "No Network Connection", message: "It looks like you aren't connected to the internet! Check your network settings and try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
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
