//
//  RequestsTableViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 7/5/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit

class RequestsTableViewController: UIViewController, UITableViewDelegate, RequestCollectionViewCellDelegate {
    let dataSource = RequestsDataSource()
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            dataSource.requestDelegate = self
            tableView.dataSource = dataSource
            tableView.delegate = self
            tableView.rowHeight = Constants.TableViewRowHeight
        }
    }
    var refreshControl: UIRefreshControl?
    var titleLabel = UILabel()
    private struct Constants {
        static let TableViewRowHeight: CGFloat = 100
        static let CollectionViewSegueIdentifier = "toRequestCollectionView"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.AllEvents)
        tableView.addSubview(refreshControl!)
        title = "Requests"
        navigationController?.navigationBar.tintColor = .redColor()
        view.backgroundColor = .whiteColor()
    }
    func refresh() {
        //reload the data
        refreshControl?.endRefreshing()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleLabel.frame = CGRectMake(0, 0, view.frame.width, view.frame.height)
        titleLabel.alpha = 0.0
        titleLabel.text = "No More Requests"
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.font = .preferredFontForTextStyle(UIFontTextStyleBody)
        titleLabel.textColor = .lightGrayColor()
        view.addSubview(titleLabel)
    }
    
    private func checkForEmptyData(animated: Bool) {
        if tableView.visibleCells().count == 0 {
            UIView.animateWithDuration(animated ? 0.5 : 0.0) {
                self.titleLabel.alpha = 1.0
                self.tableView.alpha = 0.0
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(Constants.CollectionViewSegueIdentifier, sender: indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deny = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Deny") { (rowAction, indexPath) -> Void in
            //TODO: Change this
            self.dataSource.items.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.checkForEmptyData(true)
        }
        let accept = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Accept") { (rowAction, indexPath) -> Void in
            //TODO: Change this
            self.dataSource.items.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.checkForEmptyData(true)
        }
        accept.backgroundColor = .greenColor()
        return [deny, accept]
    }
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    func requestAccepted(item: Item, forItem: Item) {
        dataSource.deleteItemAtIndex(0)
    }
    
    func requestDenied(item: Item, forItem: Item) {
        dataSource.deleteItemAtIndex(0)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = sender as? NSIndexPath {
            if let destVC = segue.destinationViewController as? RequestsViewController {
                destVC.indexPathToScrollToOnInit = indexPath
                destVC.dataSource = dataSource
            }
        }
    }

}
