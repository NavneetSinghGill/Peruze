//
//  ProfileFavoritesViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileFavoritesViewController: UIViewController, UITableViewDelegate {
  
  private struct Constants {
    static let TableViewCellHeight: CGFloat = 100
  }
  
  @IBOutlet weak var titleLabel: UILabel!
  let dataSource = ProfileFavoritesDataSource()
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.editableCells = tabBarController?.parentViewController?.tabBarController != nil
      tableView.dataSource = dataSource
      tableView.delegate = self
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel.alpha = 0.0
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    checkForEmptyData(true)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let parentVC = parentViewController as? ProfileContainerViewController {
      if let originVC = parentVC.parentViewController as? ProfileViewController {
        originVC.performSegueWithIdentifier("toFavorite", sender:dataSource)
      }
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  //MARK: Editing
  private func checkForEmptyData(animated: Bool) {
    if dataSource.favorites.count == 0 {
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
  
  func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    return UITableViewCellEditingStyle.Delete
  }
  
  func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let defaultAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Unfavorite") { (rowAction, indexPath) -> Void in
      self.dataSource.favorites.removeAtIndex(indexPath.item)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
      self.checkForEmptyData(true)
    }
    return [defaultAction]
  }
}
