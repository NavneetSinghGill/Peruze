//
//  ProfileUploadsDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileUploadsDataSource: NSObject, UITableViewDataSource {
    private struct Constants {
        static let ReuseIdentifier = "ProfileUpload"
        static let NibName = "ProfileUploadsTableViewCell"
    }
    //TODO: Get items
  var tableView: UITableView!
  var items = [Item]() {
    didSet {
      tableView.reloadData()
    }
  }
    var editableCells = true
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
        
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
            forIndexPath: indexPath) as! ProfileUploadsTableViewCell
        if items.count > indexPath.row {
            cell.titleTextLabel.text = items[indexPath.row].title
            cell.subtitleTextLabel.text = ""
            cell.descriptionTextLabel.text = items[indexPath.row].detail
            cell.circleImageView.image = UIImage(data: items[indexPath.row].image!)
            cell.accessoryType = editableCells ? .DisclosureIndicator : .None
            cell.userInteractionEnabled = editableCells
        } else {
            print("There is no cell for NSIndexPath: \(indexPath)")
        }
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return editableCells
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
