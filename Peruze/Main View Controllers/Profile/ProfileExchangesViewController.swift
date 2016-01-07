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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkForEmptyData(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        checkForEmptyData(true)
    }
    
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return Constants.TableViewCellHeight
  }
  func refresh() {
    refreshControl.endRefreshing()
  }
    
    private func checkForEmptyData(animated: Bool) {
        do {
           try self.dataSource.fetchedResultsController.performFetch()
            dispatch_async(dispatch_get_main_queue()){
                self.dataSource.tableView.reloadData()
            }
        } catch {
            
        }
        if dataSource.fetchedResultsController?.sections?[0].numberOfObjects == 0 {
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
    
    //MARK: Reloading view on fetch data from server
    func reloadFetchedData () {
        self.tableView.reloadData()
    }
}
