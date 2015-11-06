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
            getMyFriends()
            let getFacebookProfileOp = FetchFacebookUserProfile(presentationContext: self)
            getFacebookProfileOp.completionBlock = {
                
                self.spinner.stopAnimating()
                
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
        if presentedViewController == onboardVC && onboardVC != nil { print("pVC = onboard"); return }
        onboardVC = (storyboard!.instantiateViewControllerWithIdentifier(Constants.OnboardVCIdentifier) )
        if onboardVC == nil { assertionFailure("VC Pulled out of storyboard is not a UIViewController") }
        presentViewController(onboardVC!, animated: true, completion: nil)
    }
    
    private func setupLoggedInUser() {
        let getMyProfileOp = GetCurrentUserOperation(presentationContext: self, database: CKContainer.defaultContainer().publicCloudDatabase)
        getMyProfileOp.completionBlock = {
            
            self.spinner.stopAnimating()
            
            if getMyProfileOp.cancelled {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()){
                
                print("hit completion block")
                let myPerson = Person.MR_findFirstByAttribute("me", withValue: true)
                if (myPerson?.valueForKey("firstName") as? String) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                if (myPerson?.valueForKey("lastName")  as? String) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                if (myPerson?.valueForKey("image")     as? NSData) == nil { self.setupAndSegueToSetupProfileVCWithTransitionDelay(); return }
                
                //if there isn't anything wrong with my profile, segue to tab bar
                self.setupAndSegueToTabBarVC()
            }
        }
        getMyProfileOp.finishedBlock = { errors in
            FBSDKAccessToken.setCurrentAccessToken(nil)
                self.setupAndSegueToOnboardVC()
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
        tabBarVC = tabBarVC ?? storyboard!.instantiateViewControllerWithIdentifier(Constants.TabBarVCIdentifier) as? UITabBarController
        if tabBarVC == nil { assertionFailure("VC Pulled out of storyboard is not a UITabBarController")}
        tabBarVC!.selectedIndex = profileSetupVC == nil ? 0 : 1
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
                print("Friends are : \(result)")
                
                let myPerson = Person.MR_findFirstByAttribute("me", withValue: true)
                
                let friends : NSArray = (result["data"] as? NSArray)!
                
                if myPerson != nil {
                    for element in friends
                    {
                        var predicate =  NSPredicate(format: "(FacebookID = %@ AND FriendsFacebookIDs = %@) ", argumentArray: [myPerson.facebookID!,(element["id"] as? String)!])
                        self.loadFriend(predicate, finishBlock: { isPresent in
                            if isPresent == true {
                                print("\nFriend entry already present");
                            } else {
                                predicate =  NSPredicate(format: "(FriendsFacebookIDs = %@ AND FacebookID = %@) ", argumentArray: [myPerson.facebookID!,(element["id"] as? String)!])
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
                print("Error Getting Friends \(error)");
            }
        }
    }
    
    
    func loadFriend(predicate : NSPredicate , finishBlock:Bool -> Void) {
        
        //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
        //        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        //        operation.desiredKeys = ["genre", "comments"]
        operation.resultsLimit = 50
        
        var isRecordpresent = false
        
        operation.recordFetchedBlock = { (record) in
            print(record)
            isRecordpresent = true
        }
        
        operation.queryCompletionBlock = { (cursor, error) -> Void in
            finishBlock(isRecordpresent)
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
            if error != nil { print("UploadItem returned error: \(error)") }
            print("Friend : UploadItem")
        }
        
        let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //                saveItemRecordOp.qualityOfService = NSQualityOfService()
        database.addOperation(saveItemRecordOp)
    }
    
    
}
