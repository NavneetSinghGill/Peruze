//
//  ProfileExchangesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog
import CloudKit

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
    var mutualFriendIds: NSMutableSet!
    
    struct FriendsDataAndProfilePic {
        var friendData: NSDictionary!
        var profileImage: CircleImage?
    }
    var taggableFriendsData = [FriendsDataAndProfilePic]()
    var sortedFriendsData = [FriendsDataAndProfilePic]()
    var selectedFriendsToInvite: NSMutableArray = []
    
    override init() {
        super.init()
        //    let predicate = NSPredicate(value: true)
        mutualFriendIds = Model.sharedInstance().getMutualFriendsFromLocal(profileOwner, context: managedConcurrentObjectContext)
        getTaggableFriends()
//        getMutualFriendsFromCloud()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedFriendsData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.FriendsTableViewNibName, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.kFriendsTableViewCellIdentifier)
        var cell = tableView.dequeueReusableCellWithIdentifier(Constants.kFriendsTableViewCellIdentifier, forIndexPath: indexPath) as? FriendsTableViewCell
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Constants.kFriendsTableViewCellIdentifier) as? FriendsTableViewCell
        }
        let parsedObject = self.sortedFriendsData[indexPath.row]
        let userDict =  parsedObject.friendData
        cell!.nameLabel.text = userDict?.valueForKey("name") as? String
        cell!.friendDataDict = userDict
        
        if parsedObject.profileImage?.image != nil {
            cell?.profileImageView.image = parsedObject.profileImage?.image
        }
        return cell!
    }
    
    
    
    func getMutualFriends() {
        mutualFriendIds = Model.sharedInstance().getMutualFriendsFromLocal(profileOwner, context: managedConcurrentObjectContext)
        var newSortedFriendsData = [FriendsDataAndProfilePic]()
        var person: NSManagedObject!
        let profileImage = CircleImage()
        
//        if {
//            
//        }
        NSNotificationCenter.defaultCenter().postNotificationName("LNMutualFriendsCountUpdation", object: nil, userInfo: ["count":mutualFriendIds.count])
        for id in mutualFriendIds {
            person = Person.MR_findFirstOrCreateByAttribute("facebookID", withValue: id as! String)
            if person != nil {
                var data : NSMutableDictionary = [:]
                profileImage.image = nil
                if person.valueForKey("firstName") != nil && person.valueForKey("lastName") != nil {
                    data = ["name": "\(person.valueForKey("firstName")!) \(person.valueForKey("lastName")!)"]
                }
                if person.valueForKey("image") != nil {
                    profileImage.image = UIImage(data: person.valueForKey("image") as! NSData)
                }
                if person.valueForKey("recordIDName") != nil {
                    data.addEntriesFromDictionary(["recordIDName": person.valueForKey("recordIDName")!])
                }
                newSortedFriendsData.append(FriendsDataAndProfilePic(friendData: data, profileImage: profileImage))
            } else {
                let personPredicate = NSPredicate(format: "FacebookID == %@", id as! String)
                let personQuery = CKQuery(recordType: RecordTypes.Users, predicate: personPredicate)
                let personQueryOp = CKQueryOperation(query: personQuery)
                logw("abcdefgh")
                
                personQueryOp.recordFetchedBlock = {
                    (record: CKRecord!) -> Void in
                    
                }
                personQueryOp.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
                
                }
                CKContainer.defaultContainer().publicCloudDatabase.addOperation(personQueryOp)
            }
        }
        self.sortedFriendsData = newSortedFriendsData
        dispatch_async(dispatch_get_main_queue()) {
            if self.tableView != nil {
                self.tableView.reloadData()
            }
        }
    }
    
    func getTaggableFriends() {
//        self.activityIndicatorView.startAnimating()
        let request = FBSDKGraphRequest(graphPath:"/me/taggable_friends", parameters: nil);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Taggable Friends are : \(result)")
                
                var resultsArray = result.valueForKey("data") as! NSArray
                resultsArray = resultsArray.sort { (element1, element2) -> Bool in
                    return (element1.valueForKey("name") as! String) < (element2.valueForKey("name") as! String)
                }
                
                self.taggableFriendsData = []
                let newSortedFriendsData = [FriendsDataAndProfilePic]()
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
    
    //MARK: Get mutual friends
    func getMutualFriendsFromCloud() {
        if profileOwner != nil && profileOwner.facebookID != nil {
            let database = CKContainer.defaultContainer().publicCloudDatabase
            let predicate = NSPredicate(format: "FacebookID == %@", profileOwner.facebookID!)
            let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
            database.performQuery(query, inZoneWithID: nil, completionHandler: {
                (friends: [CKRecord]?, error) -> Void in
                logw("GetMissingPersonOperation Friends block")
                for friend in friends! {
                    let localFriendRecord = Friend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friend.recordID.recordName, inContext: managedConcurrentObjectContext)
                    if let facebookID = friend.objectForKey("FacebookID") {
                        localFriendRecord.setValue(facebookID, forKey: "facebookID")
                    }
                    if let friendsFacebookID = friend.objectForKey("FriendsFacebookIDs") {
                        localFriendRecord.setValue(friendsFacebookID, forKey: "friendsFacebookIDs")
                    }
                    let mutualFriends = Model.sharedInstance().getMutualFriendsFromLocal(localFriendRecord, context: managedConcurrentObjectContext)
                    localFriendRecord.setValue(mutualFriends.count, forKey: "mutualFriends")
                }
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                dispatch_async(dispatch_get_main_queue()){
                    if self.tableView != nil {
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
}
