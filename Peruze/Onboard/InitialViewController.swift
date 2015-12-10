//
//  InitialViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/14/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SystemConfiguration
import CloudKit
import CoreLocation
import SwiftLog

class InitialViewController: UIViewController {
    
    private struct Constants {
        static let OnboardVCIdentifier = "OnboardViewController"
        static let TabBarVCIdentifier = "MainTabBarViewController"
        static let ProfileVCIdentifier = "ProfileSetupNavigationController"
    }
    var spinner: UIActivityIndicatorView!
    var facebookLoginWasSuccessful = false
    var onboardVC: UIViewController?
    var tabBarVC: UITabBarController?
    var profileSetupVC: UIViewController?
    
    //MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(spinner)
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spinner.frame = view.frame
    }
    override func viewDidAppear(animated: Bool) {
        spinner.startAnimating()
        if presentedViewController == nil && presentingViewController == nil {
            segueToCorrectVC()
        }
    }
    
    //MARK: - Segues
    let opQueue = OperationQueue()
    func segueToCorrectVC() {
        if !NetworkConnection.connectedToNetwork() {
            let alert = ErrorAlertFactory.alertForNetworkWithTryAgainBlock() { [unowned self] Void in
                self.segueToCorrectVC()
            }
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        if presentedViewController != nil || presentingViewController != nil || childViewControllers.count != 0 {
            return
        }
        if storyboard == nil { assertionFailure("Storyboard is not initialized ") }
        if FBSDKAccessToken.currentAccessToken() == nil {
            spinner.stopAnimating()
            setupAndSegueToOnboardVC()
        } else {
            
            
            let getFacebookProfileOp = FetchFacebookUserProfile(presentationContext: self)
            getFacebookProfileOp.completionBlock = {
                
//                self.spinner.stopAnimating()
                
                if getFacebookProfileOp.cancelled {
                    return
                }
                self.setupLoggedInUser()
            }
            opQueue.addOperation(getFacebookProfileOp)
        }
    }
    
    @IBAction func unwindToInitialViewController(segue: UIStoryboardSegue) { /* do nothing for now */ }
    
    //MARK: - Not logged into facebook
    private func setupAndSegueToOnboardVC() {
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        if presentedViewController == onboardVC && onboardVC != nil { logw("pVC = onboard"); return }
        onboardVC = (storyboard!.instantiateViewControllerWithIdentifier(Constants.OnboardVCIdentifier) )
        if onboardVC == nil { assertionFailure("VC Pulled out of storyboard is not a UIViewController") }
        presentViewController(onboardVC!, animated: true, completion: nil)
    }
    
    private func setupLoggedInUser() {
        logw("write to the log! \(__FUNCTION__)")
        let getMyProfileOp = GetCurrentUserOperation(presentationContext: self, database: CKContainer.defaultContainer().publicCloudDatabase)
        getMyProfileOp.completionBlock = {
            
            self.spinner.stopAnimating()
            logw("\(NSDate()) \n Initial view Stopped spinner \n\n")
            if getMyProfileOp.cancelled {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()){
                let myPerson = Person.MR_findFirstByAttribute("me", withValue: true)
                if (myPerson?.valueForKey("firstName") as? String) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                if (myPerson?.valueForKey("lastName")  as? String) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                if (myPerson?.valueForKey("image")     as? NSData) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                
                //if there isn't anything wrong with my profile, segue to tab bar
                self.setupAndSegueToTabBarVC()
                self.getMyFriends()
            }
        }
        getMyProfileOp.finishedBlock = { error in
            let dict = error.userInfo as NSDictionary
            var isNewUser: String?
            var oldUserFirstName: String?
            if let val = dict["isNewUser"]{
                isNewUser = val as? String
            }
            if let val = dict["firstName"]{
                oldUserFirstName = val as? String
            }
            if isNewUser == "yes" && oldUserFirstName != nil {
                let alert = UIAlertController(title: "Peruze", message: "This iCloud account is attached to \"\(oldUserFirstName!)\". Please login to another iCloud account.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
                    FBSDKAccessToken.setCurrentAccessToken(nil)
                    self.setupAndSegueToOnboardVC()
                }))
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                FBSDKAccessToken.setCurrentAccessToken(nil)
                self.setupAndSegueToOnboardVC()
            }
        }
        opQueue.addOperation(getMyProfileOp)
    }
    
    //MARK: - Call with transition Delay
    private func setupAndSegueToSetupProfileVCWithTransitionDelay() {
        spinner.stopAnimating()
        let popTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(0.3 * Double(NSEC_PER_SEC))) // 1
        dispatch_after(popTime, dispatch_get_main_queue()) { // 2
            self.setupAndSegueToSetupProfileVC()
        }
    }
    
    //MARK: - Logged into facebook
    private func setupAndSegueToSetupProfileVC() {
        profileSetupVC = profileSetupVC ?? storyboard!.instantiateViewControllerWithIdentifier(Constants.ProfileVCIdentifier)
        if profileSetupVC == nil { assertionFailure("VC Pulled out of storyboard is not a ProfileSetupSelectPhotoViewController")}
        presentViewController(profileSetupVC!, animated: true, completion: nil)
    }
    
    //MARK: - Logged into facebook and profile setup
    private func setupAndSegueToTabBarVC() {
        logw("\(NSDate()) setupAndSegueToTabBarVC()")
        tabBarVC = tabBarVC ?? storyboard!.instantiateViewControllerWithIdentifier(Constants.TabBarVCIdentifier) as? UITabBarController
        if tabBarVC == nil { assertionFailure("VC Pulled out of storyboard is not a UITabBarController")}
        tabBarVC!.selectedIndex = profileSetupVC == nil ? 0 : 1
        for childVC in (tabBarVC?.viewControllers)! {
            _ = childVC.view
            
            if let nc : UINavigationController = childVC as? UINavigationController {
                let root = nc.viewControllers[0] as UIViewController
                _ = root.view
            }
        }
        
        self.presentViewController(tabBarVC!, animated: true, completion: nil)
    }
    
    //MARK: - Alert
    private func alertForFetchProfileError() -> UIAlertController {
        let alert = UIAlertController(title: "Error Fetching Profile", message: "It looks like there was a problem fetching your profile from our server.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
        return alert
    }
    
    
    
    func getMyFriends() {
        let request = FBSDKGraphRequest(graphPath:"/me/friends", parameters: nil);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Friends are : \(result)")
                
                let myPerson = Person.MR_findFirstByAttribute("me", withValue: true)
                
                let friends : NSArray = (result["data"] as? NSArray)!
                var ids : NSArray = friends.valueForKey("id") as! NSArray
                
                if ids.count == 0 {
                    ids = ["000000"]
                }
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(ids, forKey: "kFriends")
                defaults.synchronize()
            
                if myPerson != nil {
                    for element in friends
                    {
                        var predicate =  NSPredicate(format: "(FacebookID == %@ AND FriendsFacebookIDs == %@) ", argumentArray: [myPerson.facebookID!,(element["id"] as? String)!])
                        self.loadFriend(predicate, finishBlock: { isPresent in
                            if isPresent == true {
                                logw("\nFriend entry already present");
                            } else {
                                predicate =  NSPredicate(format: "(FriendsFacebookIDs == %@ AND FacebookID == %@) ", argumentArray: [myPerson.facebookID!,(element["id"] as? String)!])
                                self.loadFriend(predicate, finishBlock: { isPresent in
                                    if isPresent == false {
                                        self.addRecord(myPerson, element: element as! NSDictionary)
                                    }
                                })
                            }
                        })
                    }
                }
            } else {
                logw("Error Getting Friends \(error)");
            }
        }
    }
    
    
    func loadFriend(predicate : NSPredicate , finishBlock:Bool -> Void) {
        
        //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
        //        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        //        operation.desiredKeys = ["genre", "comments"]
        operation.resultsLimit = 500
        
        var isRecordpresent = false
        
        operation.recordFetchedBlock = { (record) in
            logw("\(record)")
            isRecordpresent = true
        }
        
        operation.queryCompletionBlock = { (cursor, error) -> Void in
            finishBlock(isRecordpresent)
            self.loadFriendOfFriends()
        }
        
        let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //                saveItemRecordOp.qualityOfService = NSQualityOfService()
        database.addOperation(operation)
    }
    
    
    func addRecord(myPerson : Person, element : NSDictionary) {
        var friendRecord: CKRecord
        //                if let recordIDName : String = myPerson.facebookID {
        //                    friendRecord = CKRecord(recordType: RecordTypes.Friends, recordID: CKRecordID(recordName: recordIDName))
        //                } else {
        friendRecord = CKRecord(recordType: RecordTypes.Friends)
        //                }
        friendRecord.setObject(myPerson.facebookID, forKey: "FacebookID")
        friendRecord.setObject(element["id"] as? String, forKey: "FriendsFacebookIDs")
        
        let saveItemRecordOp = CKModifyRecordsOperation(recordsToSave: [friendRecord], recordIDsToDelete: nil)
        saveItemRecordOp.modifyRecordsCompletionBlock = { (savedRecords, _, error) -> Void in
            //print any returned errors
            if error != nil { logw("UploadItem returned error: \(error)") }
            logw("Friend : UploadItem")
        }
        
        let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //                saveItemRecordOp.qualityOfService = NSQualityOfService()
        database.addOperation(saveItemRecordOp)
    }
    
    
    func loadFriendOfFriends() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if    let friendsIds : NSArray = defaults.objectForKey("kFriends") as? NSArray {
            let predicate =  NSPredicate(format: "FacebookID IN %@",friendsIds)
            
            //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
            let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
            //        query.sortDescriptors = [sort]
            
            let operation = CKQueryOperation(query: query)
            //        operation.desiredKeys = ["genre", "comments"]
            //operation.resultsLimit = 500
            
            var friendsOfFriendsList = [String]()
            operation.recordFetchedBlock = { (record) in
                logw("friendsOfFriends : \(record)")
                let fbId = record.objectForKey("FriendsFacebookIDs") as! String
                if friendsOfFriendsList.indexOf(fbId) == nil{
                    friendsOfFriendsList.append(fbId)
                }
            }
            
            
            let predicate2 =  NSPredicate(format: "FriendsFacebookIDs IN %@",friendsIds)
            
            //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
            let query2 = CKQuery(recordType: RecordTypes.Friends, predicate: predicate2)
            //        query.sortDescriptors = [sort]
            
            let operation2 = CKQueryOperation(query: query2)
            //        operation.desiredKeys = ["genre", "comments"]
//            operation2.resultsLimit = 500
            
            var friendsOfFriendsList2 = [String]()
            operation2.recordFetchedBlock = { (record) in
                logw("friendsOfFriends : \(record)")
                if record.objectForKey("FacebookID") != nil{
//                    let friendsOfFriends = defaults.objectForKey("kFriendsOfFriend") as! [String]
                    let fbId = record.objectForKey("FacebookID") as! String
                    if friendsOfFriendsList.indexOf(fbId) == nil{
                        friendsOfFriendsList2.append(fbId)
                    }
                }
            }
            
            let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
            
            operation2.queryCompletionBlock = { (cursor, error) -> Void in
                let defaults = NSUserDefaults.standardUserDefaults()
//                if defaults.objectForKey("kFriendsOfFriend") == nil {
//                   defaults.setObject(friendsOfFriendsList2, forKey: "kFriendsOfFriend")
//                } else {
//                    var friendsOfFriends = defaults.objectForKey("kFriendsOfFriend") as! [String]
//                    friendsOfFriends = friendsOfFriends + friendsOfFriendsList2
//                    defaults.setObject(friendsOfFriends, forKey: "kFriendsOfFriend")
//                }
                
                if defaults.objectForKey("kFriendsOfFriend") as? String == "0000" {
                    if friendsOfFriendsList2.count != 0 {
                        defaults.setObject(friendsOfFriendsList2, forKey: "kFriendsOfFriend")
                    }
                } else {
                    if friendsOfFriendsList2.count != 0{
                        var friendsOfFriends = defaults.objectForKey("kFriendsOfFriend") as! [String]
                        friendsOfFriends = friendsOfFriends + friendsOfFriendsList2
                        defaults.setObject(friendsOfFriends, forKey: "kFriendsOfFriend")
                    }
                }
                defaults.synchronize()
            }
            
            operation.queryCompletionBlock = { (cursor, error) -> Void in
                let defaults = NSUserDefaults.standardUserDefaults()
                if friendsOfFriendsList.count != 0{
                    defaults.setObject(friendsOfFriendsList, forKey: "kFriendsOfFriend")
                } else {
                    defaults.setObject("0000", forKey: "kFriendsOfFriend")
                }
                defaults.synchronize()
                database.addOperation(operation2)
            }
            
            //                saveItemRecordOp.qualityOfService = NSQualityOfService()
            database.addOperation(operation)
        }
    }
    
    
}
