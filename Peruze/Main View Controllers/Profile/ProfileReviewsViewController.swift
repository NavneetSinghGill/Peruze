//
//  ProfileReviewsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

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
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
    tableView.addSubview(refreshControl)
  }

  func refresh() {
    refreshControl.endRefreshing()
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return tallRowsIndexPaths.filter{$0 == indexPath}.count == 0 ? Constants.TableViewCellHeight : UITableViewAutomaticDimension
  }
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if dataSource.writeReviewEnabled && indexPath.section == 0 {
      let reviewVC = storyboard?.instantiateViewControllerWithIdentifier(Constants.WriteReviewIdentifier) as? UIViewController
      print("segue to write review")
      presentViewController(reviewVC!, animated: true, completion: nil)
    } else {
      var foundMatch: Int? = nil
      for index in 0..<tallRowsIndexPaths.count {
        if indexPath == tallRowsIndexPaths[index] {
          foundMatch = index
          break
        }
      }
      if foundMatch != nil {
        tallRowsIndexPaths.removeAtIndex(foundMatch!)
      } else {
        tallRowsIndexPaths.append(indexPath)
      }
      tableView.beginUpdates()
      tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
      tableView.endUpdates()
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
}