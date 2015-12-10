//
//  FriendsViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 30/11/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import SwiftLog

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
//            tableView.rowHeight = Constants.TableViewRowHeight
        }
    }
    struct FriendsDataAndProfilePic {
        var friendData: NSDictionary!
        var profileImage: CircleImage?
    }
    var taggableFriendsData = [FriendsDataAndProfilePic]()
    
    private struct Constants {
        static let TableViewRowHeight: CGFloat = 50
        static let kFriendsTableViewCellIdentifier = "FriendsTableViewCellIdentifier"
        static let FriendsTableViewNibName = "FriendsTableViewCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Friends"
        navigationController?.navigationBar.tintColor = .redColor()
        view.backgroundColor = .whiteColor()
        getTaggableFriends()
    }
    func getTaggableFriends() {
        let request = FBSDKGraphRequest(graphPath:"/me/taggable_friends", parameters: nil);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Taggable Friends are : \(result)")
                let resultsArray = result.valueForKey("data") as! NSArray
                self.taggableFriendsData = []
                for friendData in resultsArray {
                    let newFriendData = FriendsDataAndProfilePic(friendData: friendData as! NSDictionary, profileImage: CircleImage())
                    newFriendData.profileImage?.image = nil

                    let facebookProfileUrl = ((friendData.valueForKey("picture") as! NSDictionary).valueForKey("data") as! NSDictionary).valueForKey("url") as! String
                        let url = NSURL(string: facebookProfileUrl)
                        if let data = NSData(contentsOfURL: url!) {
                            newFriendData.profileImage?.image = UIImage(data: data)
                        }

                    self.taggableFriendsData.append(newFriendData)
                    dispatch_async(dispatch_get_main_queue()){
                        self.tableView.reloadData()
                    }
                }
            } else {
                logw("Error Getting Friends \(error)");
            }
        }
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.taggableFriendsData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.FriendsTableViewNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.kFriendsTableViewCellIdentifier)
        var cell = tableView.dequeueReusableCellWithIdentifier(Constants.kFriendsTableViewCellIdentifier, forIndexPath: indexPath) as? FriendsTableViewCell
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Constants.kFriendsTableViewCellIdentifier) as? FriendsTableViewCell
        }
        let parsedObject = self.taggableFriendsData[indexPath.row]
        let userDict =  parsedObject.friendData
        cell!.nameLabel.text = userDict?.valueForKey("name") as? String

        if parsedObject.profileImage?.image != nil {
            cell?.profileImageView.image = parsedObject.profileImage?.image
        }
        
        return cell!
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! FriendsTableViewCell
        if cell.selected {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}
