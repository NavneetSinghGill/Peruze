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

class ProfileFriendsDataSource: NSObject, UITableViewDataSource {
    private struct Constants {
        static let ReuseIdentifier = "ProfileExchange"
        static let NibName = "ProfileExchangesTableViewCell"
        static let EmptyReuseIdentifier = "EmptyCell"
        static let kFriendsTableViewCellIdentifier = "FriendsTableViewCellIdentifier"
        static let FriendsTableViewNibName = "FriendsTableViewCell"
    }
    
    
    struct FriendsDataAndProfilePic {
        var friendData: NSDictionary!
        var profileImageUrl: String!
    }
    
    var presentationContext: UIViewController!
    
    var tableView: UITableView!
    var profileOwner: Person!
    var mutualFriendIds: NSMutableSet!
    
    var taggableFriendsData = [FriendsDataAndProfilePic]()
    var sortedFriendsData = [FriendsDataAndProfilePic]()
    var selectedFriendsToInvite: NSMutableArray = []
    
    
    
    
    
    //MARK: New implementation
    
    override init() {
        super.init()
//        getMutualFriends()
        getTaggbleFriendsFromCloudAndMatch()
    }
    
    func getTaggbleFriendsFromCloudAndMatch() {
        if let parentVC = self.presentationContext as? ProfileFriendsViewController {
            parentVC.activityIndicator.startAnimating()
        }
        self.fetchLocalTaggableFriendsAndMatch()
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        if profileOwner != nil && me.valueForKey("recordIDName") as! String != profileOwner.valueForKey("recordIDName") as! String {
            dispatch_async(dispatch_get_main_queue()) {
                Model.sharedInstance().fetchTaggleFriendsRecordFromCloud(self.profileOwner, isMe: false, completionBlock: {
                    self.fetchLocalTaggableFriendsAndMatch()
                })
            }
        }
    }
    
    func fetchLocalTaggableFriendsAndMatch() {
        if self.profileOwner == nil || self.profileOwner.valueForKey("facebookID") == nil {
            return
        }
        let context = NSManagedObjectContext.MR_context()
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
        let myTaggableFriends = TaggableFriend.MR_findAllWithPredicate(NSPredicate(format: "facebookID == %@", me.valueForKey("facebookID") as! String), inContext: context)
        let otherTaggableFriends = TaggableFriend.MR_findAllWithPredicate(NSPredicate(format: "facebookID == %@", self.profileOwner.valueForKey("facebookID") as! String), inContext: context)
        
        let commonFriends: NSMutableArray = []
        
        for myFriend in myTaggableFriends {
            for otherUserfriend in otherTaggableFriends {
                if myFriend.valueForKey("firstName") as! String == otherUserfriend.valueForKey("firstName") as! String && myFriend.valueForKey("lastName") as! String == otherUserfriend.valueForKey("lastName") as! String {
                    commonFriends.addObject(myFriend)
                }
            }
        }
        self.taggableFriendsData = []
        for friend in commonFriends {
            let friendDict = [
                "name":"\(friend.valueForKey("firstName")!) \(friend.valueForKey("lastName")!)",
                "first_name":"\(friend.valueForKey("firstName")!)",
                "last_name":"\(friend.valueForKey("lastName")!)"]
            
            let newFriendData = FriendsDataAndProfilePic(friendData: friendDict, profileImageUrl: friend.valueForKey("imageUrl") as! String)
            self.taggableFriendsData.append(newFriendData)
        }
        dispatch_async(dispatch_get_main_queue()){
            //                        self.activityIndicatorView.stopAnimating()
            if self.tableView != nil {
                if let parentVC = self.presentationContext as? ProfileFriendsViewController {
                    parentVC.activityIndicator.stopAnimating()
                    parentVC.checkForEmptyData(true)
                }
                self.tableView.reloadData()
            }
        }
    }
    
//    func getMutualFriends(completionBlock: (Void -> Void) = {}) {
//        //        self.activityIndicatorView.startAnimating()
//        let fbId: String
//        if profileOwner == nil || profileOwner.valueForKey("facebookID") as? String == nil {
//            self.taggableFriendsData = []
//            return
//        }
//
////        FBSDKAccessToken.currentAccessToken().
//        fbId = profileOwner.valueForKey("facebookID") as! String
//        let fieldsDict = ["fields":"context.fields(mutual_friends.fields(name,id,picture,first_name))","limit":"5000"]//,"appsecret_proof":"0d9888220cc9669ee500c1361e41be0e"]
//        let request = FBSDKGraphRequest(graphPath:"\(fbId)?limit=5000", parameters: fieldsDict)
//        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
//            if error == nil {
//                logw("Mutual Friends are : \(result)")
//                
//                if let mutualFriends = result.valueForKey("context")!.valueForKey("mutual_friends") {
//                    var resultsArray = mutualFriends.valueForKey("data") as! NSArray
//                    resultsArray = resultsArray.sort { (element1, element2) -> Bool in
//                        return (element1.valueForKey("name") as! String) < (element2.valueForKey("name") as! String)
//                    }
//                    
//                    self.taggableFriendsData = []
//                    //                let newSortedFriendsData = [FriendsDataAndProfilePic]()
//                    for var friendData in resultsArray {
//                        friendData = friendData as! NSDictionary
//                        let newFriendData = FriendsDataAndProfilePic(friendData: friendData as! NSDictionary, profileImageUrl: ((friendData.valueForKey("picture") as! NSDictionary).valueForKey("data") as! NSDictionary).valueForKey("url") as! String)
//                        
//                        self.taggableFriendsData.append(newFriendData)
//                        
//                        dispatch_async(dispatch_get_main_queue()){
//                            //                        self.activityIndicatorView.stopAnimating()
//                            if self.tableView != nil {
//                                if let parentVC = self.presentationContext as? ProfileFriendsViewController {
//                                    parentVC.checkForEmptyData(true)
//                                }
//                                self.tableView.reloadData()
//                            }
//                        }
//                    }
//                } else {
//                    self.taggableFriendsData = []
//                }
//                if self.profileOwner.valueForKey("recordIDName") as? String != nil {
//                    let contxt = NSManagedObjectContext.MR_context()
//                    self.profileOwner.setValue(self.taggableFriendsData.count, forKey: "mutualFriends")
//                    contxt.MR_saveToPersistentStoreAndWait()
//                }
//            } else {
//                logw("Error Getting Friends \(error)")
//                self.taggableFriendsData = []
//            }
//            completionBlock()
//        }
//        dispatch_async(dispatch_get_main_queue()){
//            if self.tableView != nil {
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    
    
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
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with friendData: \(parsedObject.friendData)")
        cell!.nameLabel.text = userDict?.valueForKey("name") as? String
        cell!.friendDataDict = userDict
        cell!.profileImageView.hidden = false
        cell!.profileImageButton.hidden = true
     //   cell!.profileImageButton.layer.cornerRadius = cell!.profileImageButton.frame.size.width / 2
        
        cell!.profileImageButton.layer.masksToBounds = true
        cell!.profileImageButton.userInteractionEnabled = false
        cell!.profileImageView.userInteractionEnabled = false
        
        if parsedObject.profileImageUrl != nil {
            cell?.profileImageButton.sd_setImageWithURL(NSURL(string: parsedObject.profileImageUrl), forState: UIControlState.Normal)
            cell?.profileImageView.imageView?.image = cell?.profileImageButton.imageView?.image
        }
        return cell!
    }
    
    
    
    
    
    //MARK: EARLIER IMPLEMENTATION
    
    
//    struct FriendsDataAndProfilePic {
//        var friendData: NSDictionary!
//        var profileImageUrl: String!
//    }
    
//    override init() {
//        super.init()
//        //    let predicate = NSPredicate(value: true)
//        mutualFriendIds = Model.sharedInstance().getMutualFriendsFromLocal(profileOwner, context: managedConcurrentObjectContext)
////        getTaggableFriends()
////        getMutualFriendsFromCloud()
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.sortedFriendsData.count
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let nib = UINib(nibName: Constants.FriendsTableViewNibName, bundle: nil)
//        tableView.registerNib(nib, forCellReuseIdentifier: Constants.kFriendsTableViewCellIdentifier)
//        var cell = tableView.dequeueReusableCellWithIdentifier(Constants.kFriendsTableViewCellIdentifier, forIndexPath: indexPath) as? FriendsTableViewCell
//        if cell == nil{
//            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Constants.kFriendsTableViewCellIdentifier) as? FriendsTableViewCell
//        }
//        let parsedObject = self.sortedFriendsData[indexPath.row]
//        let userDict =  parsedObject.friendData
//        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with friendData: \(parsedObject.friendData)")
//        cell!.nameLabel.text = userDict?.valueForKey("name") as? String
//        cell!.friendDataDict = userDict
//        cell!.profileImageView.hidden = true
//        cell!.profileImageButton.hidden = false
//        cell!.profileImageButton.layer.cornerRadius = cell!.profileImageView.frame.size.width / 2
//        cell!.profileImageButton.layer.masksToBounds = true
//        
//        if parsedObject.profileImageUrl != nil {
//            cell?.profileImageButton.sd_setImageWithURL(NSURL(string: s3Url(parsedObject.profileImageUrl)), forState: UIControlState.Normal)
//        }
//        return cell!
//    }
//
//    func getMutualFriends() -> Int {
//        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
//        mutualFriendIds = Model.sharedInstance().getMutualFriendsFromLocal(profileOwner, context: managedConcurrentObjectContext)
//        var newSortedFriendsData = [FriendsDataAndProfilePic]()
//        var person: NSManagedObject!
//        var profileImageUrl = ""
//        NSNotificationCenter.defaultCenter().postNotificationName("LNMutualFriendsCountUpdation", object: nil, userInfo: ["count":mutualFriendIds.count])
//        for id in mutualFriendIds {
//            person = Person.MR_findFirstOrCreateByAttribute("facebookID", withValue: id as! String)
//            if person != nil {
//                var data : NSMutableDictionary = [:]
//                profileImageUrl = ""
//                if person.valueForKey("firstName") != nil && person.valueForKey("lastName") != nil {
//                    data = ["name": "\(person.valueForKey("firstName")!) \(person.valueForKey("lastName")!)"]
//                }
//                if person.valueForKey("imageUrl") != nil {
//                    profileImageUrl = person.valueForKey("imageUrl") as! String
//                }
//                if person.valueForKey("recordIDName") != nil {
//                    data.addEntriesFromDictionary(["recordIDName": person.valueForKey("recordIDName")!])
//                }
//                newSortedFriendsData.append(FriendsDataAndProfilePic(friendData: data, profileImageUrl: profileImageUrl))
//            } else {
//                let personPredicate = NSPredicate(format: "FacebookID == %@", id as! String)
//                let personQuery = CKQuery(recordType: RecordTypes.Users, predicate: personPredicate)
//                let personQueryOp = CKQueryOperation(query: personQuery)
//                logw("abcdefgh")
//                
//                personQueryOp.recordFetchedBlock = {
//                    (record: CKRecord!) -> Void in
//                    
//                }
//                personQueryOp.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
//                
//                }
//                CKContainer.defaultContainer().publicCloudDatabase.addOperation(personQueryOp)
//            }
//        }
//        self.sortedFriendsData = newSortedFriendsData
//        dispatch_async(dispatch_get_main_queue()) {
//            if self.tableView != nil {
//                self.tableView.reloadData()
//            }
//        }
//        return self.sortedFriendsData.count
//    }
    
//    //MARK: Get mutual friends
//    func getMutualFriendsFromCloud() {
//        if profileOwner != nil && profileOwner.facebookID != nil {
//            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with profileOwner: \(profileOwner)")
//            let database = CKContainer.defaultContainer().publicCloudDatabase
//            let predicate = NSPredicate(format: "FacebookID == %@", profileOwner.facebookID!)
//            let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
//            database.performQuery(query, inZoneWithID: nil, completionHandler: {
//                (friends: [CKRecord]?, error) -> Void in
//                logw("GetMissingPersonOperation Friends block")
//                for friend in friends! {
//                    let localFriendRecord = Friend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friend.recordID.recordName, inContext: managedConcurrentObjectContext)
//                    if let facebookID = friend.objectForKey("FacebookID") {
//                        localFriendRecord.setValue(facebookID, forKey: "facebookID")
//                    }
//                    if let friendsFacebookID = friend.objectForKey("FriendsFacebookIDs") {
//                        localFriendRecord.setValue(friendsFacebookID, forKey: "friendsFacebookIDs")
//                    }
//                    let mutualFriends = Model.sharedInstance().getMutualFriendsFromLocal(localFriendRecord, context: managedConcurrentObjectContext)
//                    localFriendRecord.setValue(mutualFriends.count, forKey: "mutualFriends")
//                }
//                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
//                dispatch_async(dispatch_get_main_queue()){
//                    if self.tableView != nil {
//                        self.tableView.reloadData()
//                    }
//                }
//            })
//        }
//    }
}
