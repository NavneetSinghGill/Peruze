//
//  ProfileFriendsViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 14/12/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import UIKit

class ProfileFriendsViewController: UIViewController, UITableViewDelegate {
    private struct Constants {
        static let TableViewCellHeight: CGFloat = 50
    }
//    private var refreshControl: UIRefreshControl!
    lazy var dataSource = ProfileFriendsDataSource()
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
//        refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
//        tableView.addSubview(refreshControl)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData", name: "FetchedPersonExchanges", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.dataSource.getMutualFriends()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        checkForEmptyData(true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constants.TableViewCellHeight
    }
//    func refresh() {
//        refreshControl.endRefreshing()
//    }
    
    private func checkForEmptyData(animated: Bool) {
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