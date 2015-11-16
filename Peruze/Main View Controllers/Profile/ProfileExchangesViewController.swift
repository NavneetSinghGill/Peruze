//
//  ProfileExchangesViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileExchangesViewController: UIViewController, UITableViewDelegate {
  private struct Constants {
    static let TableViewCellHeight: CGFloat = 100
  }
  private var refreshControl: UIRefreshControl!
  lazy var dataSource = ProfileExchangesDataSource()
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      dataSource.tableView = tableView
      tableView.dataSource = dataSource
      tableView.delegate = self
    }
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel.alpha = 0.0
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
    tableView.addSubview(refreshControl)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData", name: "FetchedPersonExchanges", object: nil)
  }
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  func refresh() {
    refreshControl.endRefreshing()
  }
    
    //MARK: Reloading view on fetch data from server
    func reloadFetchedData () {
        self.tableView.reloadData()
    }
}
