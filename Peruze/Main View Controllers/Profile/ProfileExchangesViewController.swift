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
    private let dataSource = ProfileExchangesDataSource()
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = dataSource
            tableView.delegate = self
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
        tableView.addSubview(refreshControl)
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constants.TableViewCellHeight
    }
    func refresh() {
        refreshControl.endRefreshing()
    }
}
