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
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    checkForEmptyData(true)
  }
  func refresh() {
    refreshControl.endRefreshing()
  }
  private func checkForEmptyData(animated: Bool) {
    if dataSource.reviews.count == 0 && tableView.visibleCells().count == 0 {
      UIView.animateWithDuration(animated ? 0.5 : 0.0) {
        self.titleLabel.alpha = 1.0
        self.tableView.alpha = 0.0
      }
    } else {
      UIView.animateWithDuration(animated ? 0.5 : 0.0) {
        self.titleLabel.alpha = 0.0
        self.tableView.alpha = 1.0
      }
    }
  }
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return find(tallRowsIndexPaths, indexPath) == nil ? Constants.TableViewCellHeight : UITableViewAutomaticDimension
  }
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if dataSource.writeReviewEnabled && indexPath.section == 0 {
      let reviewVC = storyboard?.instantiateViewControllerWithIdentifier(Constants.WriteReviewIdentifier) as? UIViewController
      println("segue to write review")
      presentViewController(reviewVC!, animated: true, completion: nil)
    } else {
      let foundMatch = find(tallRowsIndexPaths, indexPath)
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