//
//  ProfileUploadsViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

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
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    return [defaultAction]
  }
}
