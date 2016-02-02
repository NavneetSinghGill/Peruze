//
//  ProfileFavoritesViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

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
        dataSource.tableView = tableView
    }
  }
    var indexOfSelectedTableViewRow: Int!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel.alpha = 0.0
  }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let profileVC = self.parentViewController?.parentViewController as? ProfileViewController {
            profileVC.numberOfFavoritesLabel.text = "\(dataSource.refresh())"
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) number of favorites: \(profileVC.numberOfFavoritesLabel.text!)")
        }
        checkForEmptyData(true)
    }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let profileVC = self.parentViewController?.parentViewController as? ProfileViewController {
       profileVC.numberOfFavoritesLabel.text = "\(dataSource.refresh())"
    }
    checkForEmptyData(true)
    self.tableView.reloadData()
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let parentVC = parentViewController as? ProfileContainerViewController {
      if let originVC = parentVC.parentViewController as? ProfileViewController {
        self.indexOfSelectedTableViewRow = indexPath.row
        NSUserDefaults.standardUserDefaults().setInteger(indexPath.row, forKey: "FavouriteIndex")
        NSUserDefaults.standardUserDefaults().synchronize()
        originVC.performSegueWithIdentifier("toFavorite", sender:dataSource)
      }
    }
//    let alert = UIAlertController(title: "Peruze", message: "Not implemented yet.", preferredStyle: UIAlertControllerStyle.Alert)
//    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//    self.presentViewController(alert, animated: true, completion: nil)
//    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
    
  //MARK: Editing
    private func checkForEmptyData(animated: Bool) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) favorites.count: \(dataSource.favorites.count)")
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
    let defaultAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Remove") { (rowAction, indexPath) -> Void in
//      self.dataSource.favorites.removeAtIndex(indexPath.item)
//      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
//      self.checkForEmptyData(true)
        self.itemFavorited(self.dataSource.favorites[indexPath.item], favorite: false)
    }
    return [defaultAction]
  }
    
    func itemFavorited(item: NSManagedObject, favorite: Bool) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) item: \(item), favorite: \(favorite)")
        //favorite data
        logw("item started favorite! ")
        
        let itemRecordIDName = item.valueForKey("recordIDName") as! String
        let favoriteOp = favorite ? PostFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName) : RemoveFavoriteOperation(presentationContext: self, itemRecordID: itemRecordIDName)
        favoriteOp.completionBlock = {
            logw("favorite completed successfully")
//            self.activityIndicatorView.stopAnimating()
//            self.activityIndicatorView.alpha = 0
            var favoriteCount = 0
            dispatch_async(dispatch_get_main_queue()) {
                favoriteCount = self.dataSource.refresh()
                self.checkForEmptyData(true)
            
            if let profileVC = self.parentViewController?.parentViewController as? ProfileViewController {
                profileVC.updateViewAfterGettingResponse()
                profileVC.numberOfFavoritesLabel.text = "\(favoriteCount)"
                if let mainTabBarVC = profileVC.parentViewController?.parentViewController as? MainTabBarViewController {
                    for child in mainTabBarVC.childViewControllers {
                        if let peruseVC = child.childViewControllers[0] as? PeruseViewController {
                            peruseVC.reloadWithShuffle()
                            break
                        }
                    }
                }
                }}
        }
//        self.activityIndicatorView.startAnimating()
//        self.activityIndicatorView.alpha = 1
        OperationQueue().addOperation(favoriteOp)
    }
  
  /* Swift 2.0
  func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    let defaultAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Unfavorite") { (rowAction, indexPath) -> Void in
      self.dataSource.favorites.removeAtIndex(indexPath.item)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
      self.checkForEmptyData(true)
    }
    return [defaultAction]
  }*/
  
}
