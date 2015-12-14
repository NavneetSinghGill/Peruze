//
//  ProfileExchangesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileFriendsDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    private struct Constants {
        static let ReuseIdentifier = "ProfileExchange"
        static let NibName = "ProfileExchangesTableViewCell"
        static let EmptyReuseIdentifier = "EmptyCell"
        static let kFriendsTableViewCellIdentifier = "FriendsTableViewCellIdentifier"
        static let FriendsTableViewNibName = "FriendsTableViewCell"
    }
    var tableView: UITableView!
    var profileOwner: Person!
    var fetchedResultsController: NSFetchedResultsController!
    
    struct FriendsDataAndProfilePic {
        var friendData: NSDictionary!
        var profileImage: CircleImage?
    }
    var taggableFriendsData = [FriendsDataAndProfilePic]()
    var selectedFriendsToInvite: NSMutableArray = []
    
    override init() {
        super.init()
        //    let predicate = NSPredicate(value: true)
        getMutualFriends()
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
        cell!.friendDataDict = userDict
        
        if parsedObject.profileImage?.image != nil {
            cell?.profileImageView.image = parsedObject.profileImage?.image
        }
        return cell!
    }
    
    //MARK: Get mutual friends
    func getMutualFriends() {
//        self.activityIndicatorView.startAnimating()
//        @"fields": @"context.fields(mutual_friends)"
        if profileOwner == nil || profileOwner.facebookID == nil {
            return
        }
        let request = FBSDKGraphRequest(graphPath:profileOwner.facebookID, parameters: ["fields":"context.fields(mutual_friends)"]);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Taggable Friends are : \(result)")
                
                var resultsArray = result.valueForKey("data") as! NSArray
                resultsArray = resultsArray.sort { (element1, element2) -> Bool in
                    return (element1.valueForKey("name") as! String) < (element2.valueForKey("name") as! String)
                }
                NSNotificationCenter.defaultCenter().postNotificationName("LNMutualFriendsCountUpdation", object: nil, userInfo: ["count":resultsArray.count])
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
//                        self.activityIndicatorView.stopAnimating()
                        if self.tableView != nil {
                            self.tableView.reloadData()
                        }
                    }
                }
            } else {
                logw("Error Getting Friends \(error)");
            }
        }
        dispatch_async(dispatch_get_main_queue()){
            if self.tableView != nil {
                self.tableView.reloadData()
            }
        }
    }
}
