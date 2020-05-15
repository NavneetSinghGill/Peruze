//
//  ProfileFriendsViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 14/12/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import UIKit
import SwiftLog

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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.dataSource.presentationContext = self
//        titleLabel.alpha = 0.0
//        refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
//        tableView.addSubview(refreshControl)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFetchedData", name: "FetchedPersonExchanges", object: nil)
        self.titleLabel.alpha = 0.0
        self.activityIndicator.startAnimating()
//        self.dataSource.getMutualFriends({
//            self.activityIndicator.stopAnimating()
//            self.checkForEmptyData(true)
//        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.startAnimating()
//        self.dataSource.getMutualFriends({
//            self.activityIndicator.stopAnimating()
//            self.checkForEmptyData(true)
//        })
        self.dataSource.getTaggbleFriendsFromCloudAndMatch()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        if self.dataSource.taggableFriendsData.count == 0 {
//            self.titleLabel.hidden = false
//            self.dataSource.tableView.alpha = 0.0
//        } else {
//            self.titleLabel.hidden = true
//            self.dataSource.tableView.alpha = 1.0
//        }
//        checkForEmptyData(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Constants.TableViewCellHeight
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let parsedObject = dataSource.taggableFriendsData[indexPath.row]
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with friendData: \(parsedObject.friendData)")
        NSNotificationCenter.defaultCenter().postNotificationName("RefreshUser", object: nil, userInfo: ["friendData":parsedObject.friendData, "imageUrl": parsedObject.profileImageUrl])
    }

    
    func checkForEmptyData(animated: Bool) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) mutualFriendsData.count: \(dataSource.taggableFriendsData.count)")
        NSNotificationCenter.defaultCenter().postNotificationName("LNMutualFriendsCountUpdation", object: nil, userInfo: ["count":dataSource.taggableFriendsData.count])
        if dataSource.taggableFriendsData.count == 0 {
            UIView.animateWithDuration(animated ? 0.5 : 0.0) {
                if !self.activityIndicator.isAnimating() {
                    self.titleLabel.alpha = 1.0
                }
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
         dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
}