//
//  ProfileReviewsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

class ProfileReviewsViewController: UIViewController, UITableViewDelegate {
  private struct Constants {
    static let TableViewCellHeight: CGFloat = 100
    static let WriteReviewIdentifier = "ReviewNavigationController"
  }
  let dataSource = ProfileReviewsDataSource()
  private var tallRowsIndexPaths = [NSIndexPath]()
  private var refreshControl: UIRefreshControl!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.writeReviewEnabled = tabBarController?.parentViewController?.tabBarController == nil
      tableView.dataSource = dataSource
      tableView.delegate = self
      tableView.estimatedRowHeight = Constants.TableViewCellHeight
      dataSource.tableView = tableView
    }
  }
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
  override func viewDidLoad() {
    super.viewDidLoad()
    logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refreshWithoutActivityIndicator", forControlEvents: UIControlEvents.AllEvents)
    tableView.addSubview(refreshControl)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData", name: "FetchedPersonReviews", object: nil)
    
    let fetchCount = self.dataSource.fetchData()
    if fetchCount == 0{
        self.titleLabel.alpha = 1
    } else {
        self.titleLabel.alpha = 0
    }
    if tabBarController == nil {
        self.refresh()
    }
  }
    
    override func viewWillLayoutSubviews() {
        let fetchCount = self.dataSource.fetchData()
        if fetchCount == 0{
            self.titleLabel.alpha = 1
        } else {
            self.titleLabel.alpha = 0
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let fetchCount = self.dataSource.fetchData()
        if fetchCount == 0{
            self.titleLabel.alpha = 1
        } else {
            self.titleLabel.alpha = 0
        }
    }
    
    func refreshWithoutActivityIndicator() {
        self.activityIndicatorView.alpha = 0
        self.refresh()
    }
    
  let opQueue = OperationQueue()
    func refresh() {
 //    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    let recordIDName: String
    if dataSource.profileOwner != nil && dataSource.profileOwner.valueForKey("recordIDName") != nil{
        recordIDName = dataSource.profileOwner.valueForKey("recordIDName") as! String
    } else {
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        recordIDName = me.valueForKey("recordIDName") as! String
    }
    let reviewOp = GetReviewsOperation(recordID: CKRecordID(recordName: recordIDName))
    reviewOp.completionBlock = {
      dispatch_async(dispatch_get_main_queue()) {
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.alpha = 1
        self.refreshControl.endRefreshing()
        if self.dataSource.fetchData() > 0 {
            self.titleLabel.alpha = 0
        } else {
            self.titleLabel.alpha = 1
        }
      }
    }
    self.activityIndicatorView.startAnimating()
    opQueue.addOperation(reviewOp)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return tallRowsIndexPaths.filter{$0 == indexPath}.count == 0 ? Constants.TableViewCellHeight : UITableViewAutomaticDimension
  }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) indexPath: \(indexPath)")
    if dataSource.writeReviewEnabled && indexPath.section == 0 {
      let reviewVC = storyboard?.instantiateViewControllerWithIdentifier(Constants.WriteReviewIdentifier)
      logw("segue to write review")
        if let writeReviewVC = reviewVC?.childViewControllers[0] as? WriteReviewViewController {
            writeReviewVC.profileOwner = self.dataSource.profileOwner
        }
      presentViewController(reviewVC!, animated: true, completion: nil)
    } else {
//      var foundMatch: Int? = nil
//      for index in 0..<tallRowsIndexPaths.count {
//        if indexPath == tallRowsIndexPaths[index] {
//          foundMatch = index
//          break
//        }
//      }
//      if foundMatch != nil {
//        tallRowsIndexPaths.removeAtIndex(foundMatch!)
//      } else {
//        tallRowsIndexPaths.append(indexPath)
//      }
//      tableView.beginUpdates()
//      tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
//      tableView.endUpdates()
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.WriteReviewIdentifier {
            
        }
    }
    
    //MARK: Reloading view on fetch data from server
    func reloadFetchedData () {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            self.dataSource.personRecordID = notification.object as! String;
            self.refresh()
        })
    }
}