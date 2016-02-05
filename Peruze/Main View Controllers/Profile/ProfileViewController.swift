//
//  ProfileViewController.swift
//  Peruse, LLC
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

class ProfileViewController: UIViewController {
    
    private struct Constants {
        struct ViewControllerIndexes {
            static let Uploads = 0
            static let Reviews = 1
            static let Favorites = 2
            static let Exchanges = 3
            static let MutualFriends = 4
        }
        struct SegueIdentifiers {
            static let Upload = "toUpload"
            static let Favorite = "toFavorite"
        }
        struct Images {
            static let Uploads = "Profile_Upload"
            static let UploadsFilled = "Profile_Upload_Filled"
            static let Reviews = "Profile_Star"
            static let ReviewsFilled = "Profile_Star_Filled"
            static let Favorites = "Profile_Heart"
            static let FavoritesFilled = "Profile_Heart_Filled"
            static let Exchanges = "Profile_Exchange"
            static let ExchangesFilled = "Profile_Exchange_Filled"
            static let Friends = "Profile_Friend"
            static let FriendsFilled = "Profile_Friend_Filled"
        }
    }
    
    //MARK: - Variables
    var personForProfile: Person?
    var isShowingMyProfile = false
    @IBOutlet weak var profileImageView: CircleImage!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var numberOfExchangesLabel: UILabel!
    @IBOutlet weak var numberOfFavoritesLabel: UILabel!
    @IBOutlet weak var numberOfUploadsLabel: UILabel!
    @IBOutlet weak var uploadsButton: UIButton!
    @IBOutlet weak var reviewsButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var exchangesButton: UIButton!
    @IBOutlet weak var starView: StarView!
    @IBOutlet weak var containerView: UIView!
    
    //OU for other user
    @IBOutlet weak var ouProfileImageView: CircleImage!
    @IBOutlet weak var ouProfileNameLabel: UILabel!
    @IBOutlet weak var ouNumberOfFriendsLabel: UILabel!
    @IBOutlet weak var ouNumberOfUploadsLabel: UILabel!
    @IBOutlet weak var ouUploadsButton: UIButton!
    @IBOutlet weak var ouReviewsButton: UIButton!
    @IBOutlet weak var ouFriendsButton: UIButton!
    @IBOutlet weak var ouStarView: StarView!
    @IBOutlet weak var profileContainerBottomConstraint: NSLayoutConstraint!
    
    var isOtherUser: Bool!
    var newProfilePic: Bool!
    var tempImageView1: UIImageView!
    var uploadImageInProgress = false
    
    private let containerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    @IBOutlet weak var otherUserProfileSuperView: UIView!
    var friendsRecords : NSMutableArray = []
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) segue: \(segue), sender: \(sender)")
        if segue.identifier == "toUploadDetail" {
            if let profileUploadsDataSource = sender as? ProfileUploadsDataSource,
                let uploadsDetailScreen = segue.destinationViewController.childViewControllers[0] as? ProfileUploadsCollectionViewController {
                    uploadsDetailScreen.dataSource = profileUploadsDataSource
                    uploadsDetailScreen.navigationItem.title = "\(personForProfile?.valueForKey("firstName")! as! String)\'s uploads"
            }
        }
    }
    
    //MARK: - UIViewController Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "friendsCountUpdation:", name: "LNMutualFriendsCountUpdation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reviewsCountUpdation:", name: "LNReviewsCountUpdation", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshProfileVCData", name: "refreshProfileVCData", object: nil)
        
        numberOfExchangesLabel.text = "0"
        numberOfFavoritesLabel.text = "0"
        numberOfUploadsLabel.text = "0"
        ouNumberOfFriendsLabel.text = "0"
        ouNumberOfUploadsLabel.text = "0"
        
        
        //check for a person, if there's no person, then it's my profile
        if personForProfile == nil {
            personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
        }
        //setup the known information about the person
        if (personForProfile?.valueForKey("imageUrl") as? String != nil) {
//            profileImageView.image = UIImage(data: personForProfile!.valueForKey("image") as! NSData)
//            ouProfileImageView.image = UIImage(data: personForProfile!.valueForKey("image") as! NSData)
            tempImageView1 = UIImageView()
            tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(personForProfile!.valueForKey("imageUrl") as! String)), completed: { (image, error, sdImageCacheType, url) -> Void in
                self.profileImageView.image = image
                self.ouProfileImageView.image = image
                self.view.setNeedsDisplay()
            })
            profileNameLabel.text = (personForProfile!.valueForKey("firstName") as! String)
            ouProfileNameLabel.text = (personForProfile!.valueForKey("firstName") as! String)
        }
        //TODO: set #ofStars
        
        
        //hide the container view and start loading data
        containerView.alpha = 0.0
        containerSpinner.startAnimating()
        view.addSubview(containerSpinner)
        
        //Fetch user all info if not fetched
        let defaults = NSUserDefaults.standardUserDefaults()
        let shouldFetchAllInfo = defaults.boolForKey("keyFetchedUserProfile")
        if shouldFetchAllInfo == true {
            self.containerSpinner.stopAnimating()
            UIView.animateWithDuration(0.5, animations: { self.containerView.alpha = 1.0 }, completion: { (success) -> Void in
                self.updateChildViewControllers()
                self.getMyFriendsFor()
            })
            
            self.updateViewAfterGettingResponse()
            
        }
        NSUserDefaults.standardUserDefaults().setValue("no", forKey: "isOtherUser")
        if tabBarController == nil {
            let done = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done:")
            done.tintColor = UIColor.redColor()
            navigationItem.rightBarButtonItem = done
            NSUserDefaults.standardUserDefaults().setValue("yes", forKey: "isOtherUser")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
        uploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
        reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        ouReviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
        exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
        starView.backgroundColor = .clearColor()
        ouStarView.backgroundColor = .clearColor()
        starView.numberOfStars = 0
        ouStarView.numberOfStars = 0
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "profileUpdate:", name: "profileUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetchUserProfileIfNeeded", name: "FetchUserProfileIfNeeded", object: nil)
        if NSUserDefaults.standardUserDefaults().valueForKey("isOtherUser") == nil || NSUserDefaults.standardUserDefaults().valueForKey("isOtherUser") as? String == "no"{
            isOtherUser = false
            NSUserDefaults.standardUserDefaults().setValue("no", forKey: "isOtherUser")
            NSUserDefaults.standardUserDefaults().synchronize()
        } else {
            isOtherUser = true
        }
        otherUserProfileSuperView.hidden = !isOtherUser
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshUser:", name: "RefreshUser", object: nil)
        newProfilePic = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.setNeedsDisplay()
        if self.tabBarController != nil {
            if !newProfilePic {
                if uploadImageInProgress == false {
                    self.personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
                    tempImageView1 = UIImageView()
                    tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(personForProfile!.valueForKey("imageUrl") as! String)), completed: { (image, error, sdImageCacheType, url) -> Void in
                        self.profileImageView.image = image
                        self.view.setNeedsDisplay()
                    })
                }
            }
            newProfilePic = false
        } else {
            self.profileContainerBottomConstraint.constant = 0
        }
        for superChildVC in childViewControllers {
            if let profileContainerVC = superChildVC as? ProfileContainerViewController {
                for childVC in profileContainerVC.childViewControllers{
                    if let profileReviewsVC = childVC as? ProfileReviewsViewController {
                        profileReviewsVC.dataSource.fetchData()
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updateViewAfterGettingResponse()
        if self.tabBarController == nil {
            self.getMyUploadedItems()
        }
    }
    
    func getMyUploadedItems() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let personRecordID = CKRecordID(recordName: self.personForProfile?.valueForKey("recordIDName") as! String)
        
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", personRecordID)
        let getItemsQuery = CKQuery(recordType: RecordTypes.Item, predicate: predicate)
        let getItemsOperation = CKQueryOperation(query: getItemsQuery)
        
        //handle returned objects
        getItemsOperation.recordFetchedBlock = {
            (record: CKRecord!) -> Void in
            
            let context = NSManagedObjectContext.MR_context()
            let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                withValue: record.recordID.recordName, inContext: context)
            
            localUpload.setValue(record.recordID.recordName, forKey: "recordIDName")
            
            let ownerRecordIDName = record.creatorUserRecordID!.recordName
            
            if ownerRecordIDName == "__defaultOwner__" {
                let owner = Person.MR_findFirstByAttribute("me",
                    withValue: true,
                    inContext: context)
                localUpload.setValue(owner, forKey: "owner")
            } else {
                if let owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                    withValue: ownerRecordIDName,
                    inContext: context){
                        localUpload.setValue(owner, forKey: "owner")
                }
            }
            
            if let title = record.objectForKey("Title") as? String {
                localUpload.setValue(title, forKey: "title")
                if title == "Crop Mobile"{
                    
                }
            }
            
            if let detail = record.objectForKey("Description") as? String {
                localUpload.setValue(detail, forKey: "detail")
            }
            
            if let ownerFacebookID = record.objectForKey("OwnerFacebookID") as? String {
                localUpload.setValue(ownerFacebookID, forKey: "ownerFacebookID")
            } else {
                localUpload.setValue("noId", forKey: "ownerFacebookID")
            }
            
//            if let imageAsset = record.objectForKey("Image") as? CKAsset {
//                let imageData = NSData(contentsOfURL: imageAsset.fileURL)
//                localUpload.setValue(imageData, forKey: "image")
//            }
            
            if let itemLocation = record.objectForKey("Location") as? CLLocation {//(latitude: itemLat.doubleValue, longitude: itemLong.doubleValue)
                
                if let latitude : Double = Double(itemLocation.coordinate.latitude) {
                    localUpload.setValue(latitude, forKey: "latitude")
                }
                
                if let longitude : Double = Double(itemLocation.coordinate.longitude) {
                    localUpload.setValue(longitude, forKey: "longitude")
                }
            }
            
            if let isDelete = record.objectForKey("IsDeleted") as? Int {
                localUpload.setValue(isDelete, forKey: "isDelete")
            }
            
            if let imageUrl = record.objectForKey("ImageUrl") as? String {
                localUpload.setValue(imageUrl, forKey: "imageUrl")
            }
//            
//            if localUpload.hasRequested != "yes" {
//                localUpload.setValue("no", forKey: "hasRequested")
//            }
            
            //save the context
            context.MR_saveToPersistentStoreAndWait()
        }
        getItemsOperation.queryCompletionBlock = {
            (cursor, error) -> Void in
            if error == nil {
                logw("Fetched all upload items in Profile uploads VC")
            } else {
                logw("Error Fetching all upload items in Profile uploads VC")
            }
        }
        OperationQueue().addOperation(getItemsOperation)
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerSpinner.frame = containerView.frame
    }
    func profileUpdate(noti:NSNotification) {
        if noti.userInfo != nil {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with userInfo: \(noti.userInfo!)")
        }
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
        let userInfo:NSDictionary = noti.userInfo!
        let updatedProfileImage = (userInfo.valueForKey("circleImage") as? CircleImage)!
        uploadImageInProgress = true
        self.view.reloadInputViews()
        let uniqueImageName = createUniqueName()
        let uploadRequest = Model.sharedInstance().uploadRequestForImageWithKey(uniqueImageName, andImage: updatedProfileImage.image!)
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        transferManager.upload(uploadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {task in
            if task.error != nil {
                logw("ProfileViewController profile Image upload to s3 failed with error: \(task.error)")
            } else {
                logw("ProfileViewController profile Image upload to s3 success")
                self.uploadImageInProgress = false
                let imageData = UIImagePNGRepresentation(updatedProfileImage.image!)
                me!.setValue(imageData, forKey: "image")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                me!.setValue(uniqueImageName, forKey: "imageUrl")
                managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                let op = PostUserOperation(presentationContext: self, database: CKContainer.defaultContainer().publicCloudDatabase, context: managedConcurrentObjectContext)
                OperationQueue().addOperation(op)
                self.tempImageView1 = UIImageView()
                self.tempImageView1.sd_setImageWithURL(NSURL(string: s3Url(uniqueImageName)), completed: { (image, error, sdImageCacheType, url) -> Void in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.profileImageView.image = nil
                        self.profileImageView.image = image
                        self.view.setNeedsDisplay()
                    }
                })
            }
            return nil
        })
        dispatch_async(dispatch_get_main_queue()) {
            self.newProfilePic = true
            self.profileImageView.image = nil
            self.profileImageView.image = updatedProfileImage.image!
            self.view.setNeedsDisplay()
        }
    }
    
    func refreshProfileVCData() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        dispatch_async(dispatch_get_main_queue()) {
//            logw("=============================================\(NSThread.isMainThread())")
            self.ouNumberOfUploadsLabel.text = String(Int(self.personForProfile!.uploads!.count))
            self.ouNumberOfFriendsLabel.text = String(self.personForProfile!.mutualFriends!)
        }
    }
    
    //MARK: - Handling Tab Segues
    @IBAction func uploadsTapped(sender: AnyObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        uploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
        ouUploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
        reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        ouReviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
        exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
        ouFriendsButton.imageView!.image = UIImage(named: Constants.Images.Friends)
        for viewController in childViewControllers {
            if let vc = viewController as? ProfileContainerViewController {
                vc.profileOwner = personForProfile
                vc.viewControllerNumber = Constants.ViewControllerIndexes.Uploads
            }
        }
    }
    @IBAction func reviewsTapped(sender: AnyObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
        ouUploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
        reviewsButton.imageView!.image = UIImage(named: Constants.Images.ReviewsFilled)
        ouReviewsButton.imageView!.image = UIImage(named: Constants.Images.ReviewsFilled)
        favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
        exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
        ouFriendsButton.imageView!.image = UIImage(named: Constants.Images.Friends)
        for viewController in childViewControllers {
            if let vc = viewController as? ProfileContainerViewController {
                vc.profileOwner = personForProfile
                vc.viewControllerNumber = Constants.ViewControllerIndexes.Reviews
            }
        }
    }
    @IBAction func favoritesTapped(sender: AnyObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
        reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        favoritesButton.imageView!.image = UIImage(named: Constants.Images.FavoritesFilled)
        exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
        for viewController in childViewControllers {
            if let vc = viewController as? ProfileContainerViewController {
                vc.profileOwner = personForProfile
                vc.viewControllerNumber = Constants.ViewControllerIndexes.Favorites
            }
        }
    }
    @IBAction func exchangesTapped(sender: AnyObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
        reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
        exchangesButton.imageView!.image = UIImage(named: Constants.Images.ExchangesFilled)
        for viewController in childViewControllers {
            if let vc = viewController as? ProfileContainerViewController {
                vc.profileOwner = personForProfile
                vc.viewControllerNumber = Constants.ViewControllerIndexes.Exchanges
            }
        }
    }
    @IBAction func friendsTapped(sender: AnyObject) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        ouUploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
        ouReviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
        ouFriendsButton.imageView!.image = UIImage(named: Constants.Images.FriendsFilled)
        for viewController in childViewControllers {
            if let vc = viewController as? ProfileContainerViewController {
                vc.profileOwner = personForProfile
                vc.viewControllerNumber = Constants.ViewControllerIndexes.MutualFriends
            }
        }
    }
    
    func done(sender: UIBarButtonItem) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.dismissViewControllerAnimated(true, completion: nil)
        NSUserDefaults.standardUserDefaults().setValue("isOtherUser", forKey: "no")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    //MARK: - Setting Info for Child View Controllers
    private func updateChildViewControllers() {
        logw("\(self.childViewControllers)")
        
        for childVC in childViewControllers {
            if let container = childVC as? ProfileContainerViewController {
                _ = container.view
                container.profileOwner = personForProfile
                for childVC in container.childViewControllers {
                    _ = childVC.view
                    if let friendsVC = childVC as? ProfileFriendsViewController {
                        friendsVC.dataSource.profileOwner = personForProfile
                    }
                    
                }
            }
        }
    }
    
    func updateViewAfterGettingResponse() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let predicate = NSPredicate(format: "status == %@", NSNumber(integer: ExchangeStatus.Completed.rawValue))
        let ex = Exchange.MR_findAllWithPredicate(predicate, inContext: managedConcurrentObjectContext)
        numberOfExchangesLabel.text = String(ex.count)
        //        numberOfExchangesLabel.text = String(self.personForProfile!.exchanges!.count)
        self.personForProfile = Person.MR_findFirstByAttribute("recordIDName", withValue: self.personForProfile!.valueForKey("recordIDName") as! String, inContext: managedConcurrentObjectContext)
        
        //Refresh favorites
        var fav = NSSet(array: [])
        if let favorites = self.personForProfile!.favorites! as? NSSet {
            if let favoriteObjs = favorites.allObjects as? [NSManagedObject] {
                for favoriteObj in favoriteObjs{
                    if favoriteObj.valueForKey("hasRequested") != nil && favoriteObj.valueForKey("title") != nil && favoriteObj.valueForKey("hasRequested") as! String == "no" && favoriteObj.valueForKey("isDelete") as! Int != 1 {
                        //                                        fav.append(favoriteObj)
                        if fav.count == 0 {
                            fav = NSSet(array: [favoriteObj])
                        } else {
                            fav = NSSet(array: fav.allObjects + [favoriteObj])
                        }
                    }
                }
            }
        }
        let favoriteCount: Int!
        if fav.count == 0{
            favoriteCount = 0
        } else {
            favoriteCount = fav.count
        }
        
        //refresh uploads
        var newUploads = NSSet(array: [])
        if let currentUploads = self.personForProfile!.uploads! as? NSSet {
            if let uploadObjs = currentUploads.allObjects as? [NSManagedObject] {
                for uploadObj in uploadObjs{
                    if uploadObj.valueForKey("isDelete") as! Int != 1 {
                        if newUploads.count == 0 {
                            newUploads = NSSet(array: [uploadObj])
                        } else {
                            newUploads = NSSet(array: newUploads.allObjects + [uploadObj])
                        }
                    }
                }
            }
        }
        let uploadCount: Int!
        if newUploads.count == 0{
            uploadCount = 0
        } else {
            uploadCount = newUploads.count
        }
        
        numberOfFavoritesLabel.text = String(favoriteCount)
        numberOfUploadsLabel.text = String(uploadCount)
        
        ouNumberOfUploadsLabel.text = String(uploadCount)
        ouNumberOfFriendsLabel.text = String(self.personForProfile!.mutualFriends!)
    }
    
    func getAllDataOfCurentUser() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(false, forKey: "keyFetchedUserProfile")
        defaults.synchronize()
        
        
        
        //get the updated information for the profile
        let personForProfileRecordID = personForProfile?.valueForKey("recordIDName") as! String
        let completePersonRecordID = CKRecordID(recordName: personForProfile?.valueForKey("recordIDName") as! String)
        let completePerson = GetFullProfileOperation(
            personRecordID: completePersonRecordID,
            context: managedConcurrentObjectContext,
            database: CKContainer.defaultContainer().publicCloudDatabase,
            completionHandler: {
                logw("\(NSDate())\nFinished GetFullProfileOperation")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let completeProfile = Person.MR_findFirstByAttribute("recordIDName", withValue: personForProfileRecordID)
                    self.personForProfile = completeProfile
                    self.containerSpinner.stopAnimating()
                    UIView.animateWithDuration(0.5, animations: { self.containerView.alpha = 1.0 }, completion: { (success) -> Void in
                        self.updateChildViewControllers()
                    })
                    self.updateViewAfterGettingResponse()
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setBool(true, forKey: "keyFetchedUserProfile")
                    defaults.synchronize()
                })
        })
        OperationQueue().addOperation(completePerson)
    }
    
    func checkForUserInfo() -> Bool {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        let defaults = NSUserDefaults.standardUserDefaults()
        let shouldFetchAllInfo = defaults.boolForKey("keyFetchedUserProfile")
        if shouldFetchAllInfo == false {
            getAllDataOfCurentUser()
        }
        return shouldFetchAllInfo
    }
    
    
    //MARK: - notification Obeserver method
    func fetchUserProfileIfNeeded() {
        checkForUserInfo()
    }
    
    
    
    func getMyFriendsFor() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        
        self.friendsRecords.removeAllObjects()
        if let myPerson = Person.MR_findFirstByAttribute("me", withValue: true) {
            var predicate =  NSPredicate(format: "(FacebookID == %@) ", argumentArray: [myPerson.facebookID!])
            self.loadFriend(predicate, finishBlock: { friendsRecords in
                if friendsRecords.count > 0 {
                    self.friendsRecords.addObjectsFromArray(friendsRecords.valueForKey("FriendsFacebookIDs") as! [AnyObject])
                }
                predicate =  NSPredicate(format: "(FriendsFacebookIDs == %@) ", argumentArray: [myPerson.facebookID!])
                self.loadFriend(predicate, finishBlock: { friendsRecords in
                    self.friendsRecords.addObjectsFromArray(friendsRecords.valueForKey("FacebookID") as! [AnyObject])
                })
            })
        }
        
    }
    
    
    func loadFriend(predicate : NSPredicate , finishBlock:NSArray -> Void) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        
        //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
        //        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        //        operation.desiredKeys = ["genre", "comments"]
        operation.resultsLimit = 5000
        
        let friendsRecords: NSMutableArray = []
        
        operation.recordFetchedBlock = { (record) in
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) recordFetchedBlock : \(record)")
            friendsRecords.addObject(record)
        }
        
        operation.queryCompletionBlock = { (cursor, error) -> Void in
            finishBlock(friendsRecords)
        }
        
        let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //                saveItemRecordOp.qualityOfService = NSQualityOfService()
        database.addOperation(operation)
    }
    
    func friendsCountUpdation(notification: NSNotification) {
        if notification.userInfo != nil {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with userInfo \(notification.userInfo!)")
            let userInfo: NSDictionary = notification.userInfo!
            let count = userInfo.valueForKey("count") as! Int
            self.ouNumberOfFriendsLabel.text = "\(count)"
        }
    }
    
    func reviewsCountUpdation(notification: NSNotification) {
        if notification.userInfo != nil {
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with userInfo \(notification.userInfo!)")
            let userInfo: NSDictionary = notification.userInfo!
            let count = userInfo.valueForKey("count") as! Float
            if self.isShowingMyProfile {
                self.starView.numberOfStars = count
            } else {
                self.ouStarView.numberOfStars = count
            }
        }
    }
    
    
    func refreshUser(notification:NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            if notification.userInfo != nil {
                logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) with userInfo \(notification.userInfo!)")
                //            ["friendData":parsedObject.friendData, "circleImage": parsedObject.profileImage]
                let userInfo : NSDictionary = notification.userInfo!
                let userDictionary = userInfo.valueForKey("friendData")
                let userId = userDictionary!.valueForKey("recordIDName") as? String
                let person = Person.MR_findFirstWithPredicate(NSPredicate(format: "recordIDName = %@",userId!))
                if self.personForProfile != nil && self.personForProfile!.valueForKey("me") as! Bool == true {
                    return
                }
                self.personForProfile = person
                if (self.personForProfile?.valueForKey("imageUrl") as? String != nil) {
                    self.ouProfileImageView.imageView?.sd_setImageWithURL(NSURL(string: s3Url(self.personForProfile!.valueForKey("imageUrl") as! String)))
                    self.ouProfileNameLabel.text = (self.personForProfile!.valueForKey("firstName") as! String)
                }
                self.updateViewAfterGettingResponse()
                for viewController in self.childViewControllers {
                    if let vc = viewController as? ProfileContainerViewController {
                        for childVC in vc.childViewControllers {
                            if let reviewVC = childVC as? ProfileReviewsViewController {
                                reviewVC.dataSource.writeReviewEnabled = true
                            }
                        }
                        vc.profileOwner = self.personForProfile
                        vc.viewControllerNumber = Constants.ViewControllerIndexes.Uploads
                        vc.viewControllerNumber = Constants.ViewControllerIndexes.Reviews
                        vc.viewControllerNumber = Constants.ViewControllerIndexes.MutualFriends
                        vc.viewControllerNumber = Constants.ViewControllerIndexes.Uploads
                        self.uploadsTapped(UIButton())
                    }
                }
            }
        }
    }
    
    
}
