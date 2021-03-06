//
//  Model.swift
//  Peruse
//
//  Created by Phillip Trent on 7/4/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit
import SwiftLog

struct NotificationCenterKeys {
  static let PeruzeItemsDidFinishUpdate = "PeruseItemsDidFinishUpdate"
  static let UploadItemDidFinishSuccessfully = "UploadItemDidFinishSuccessfully"
  static let RequestsDidFinishUpdate = "RequestsDidFinishUpdate"
  static let ChatsDidFinishUpdate = "ChatsDidFinishUpdate"
  static let MessagesDidFinishUpdate = "MessagesDidFinishUpdate"
  static let UploadsDidFinishUpdate = "UploadsDidFinishUpdate"
  static let ReviewsDidFinishUpdate = "ReviewsDidFinishUpdate"
  static let FavoritesDidFinishUpdate = "FavoritesDidFinishUpdate"
  static let ExchangesDidFinishUpdate = "ExchangesDidFinishUpdate"
  static let LocationDidStartUpdates = "LocationDidStartUpdates"
  static let LocationDidFinishUpdates = "LocationDidFinishUpdates"
  static let LNRefreshChatScreenForUpdatedExchanges = "RefreshChatScreenForUpdatedExchanges"
    static let LNRefreshRequestScreenWithLocalData = "RefreshRequestScreenWithLocalData"
    static let AppDidBecomeActiveNotificationName = "applicationDidBecomeActive"
    static let LNAcceptedRequest = "AcceptedRequest"
  struct Error {
    static let PeruzeUpdateError = "PeruseUpdateError"
    static let UploadItemError = "UploadItemError"
  }
    
    static let UpdateItemsOnFilterChange = "UpdateItemsOnFilterChange"
}

struct BuckeyKeys {
    static let bucket = "peruze"
}

struct NotificationMessages {
    static let NewOfferMessage = "You have received a new offer."
    static let UpdateOfferMessage = "An offer updated for you"
    static let NewChatMessage = "You have received a new  message."
    static let ExchangeRecall = "Did you complete your exchange"
    static let ItemAdditionOrUpdation = "A new item has been added"
    static let ItemDeletion = "An item has been deleted"
    static let UserUpdate = "An User updated"
    static let AcceptedOfferMessage = "Your recent offer has been accepted."
}

struct NotificationCategoryMessages {
    static let NewOfferMessage = "categoryOffer"
    static let UpdateOfferMessage = "categoryOfferUpdate"
    static let NewChatMessage = "categoryMessage"
    static let ExchangeRecall = "Did you complete your exchange.."
    static let ItemAdditionOrUpdation = "Item added or updated"
    static let ItemDeletion = "Item Deleted"
    static let UserStatusUpdate = "User update"
    static let AcceptedOfferMessage = "acceptedOfferMessage"
    static let NewReview = "Review added"
}

struct UniversalConstants {
    static let kIsPushNotificationOn = "isPushNotificationOn"
    static let kIsPostingToFacebookOn = "isPostingToFacebookOn"
    static let kSetSubscriptions = "setSubscriptions"
    static let kCurrentProfilePicUrl = "currentProfilePicUrl"
    static let kIsScreenRefreshInProgress = "isScreenRefreshInProgress"
}

struct SubscritionTypes {
  static let PeruzeItemUpdates = "PeruzeItemUpdates"
}
struct RecordTypes {
  static let Item = "Item"
  static let Exchange = "Exchange"
  static let Review = "Review"
  static let Users = "Users"
  static let Message = "Chat"
  static let Friends = "Friends"
  static let UsersStatus = "UsersStatus"
  static let TaggableFriends = "TaggableFriends"
}

struct SubscriptionIDs {
    static let NewOfferSubscriptionID = "newOfferSubscriptionID"
    static let AcceptedOfferSubscriptionID = "acceptedOfferSubscriptionID"
    static let ChatSubscriptionID = "chatSubscriptionID"
}
struct FriendsDataAndProfilePic {
    var friendData: NSDictionary!
    var profileImageUrl: String!
}

class Model: NSObject, CLLocationManagerDelegate {
    
    var friendsRecords : NSMutableArray = []
    private var publicDB = CKContainer.defaultContainer().publicCloudDatabase
    private let locationAccuracy: CLLocationAccuracy = 200 //meters
    class func sharedInstance() -> Model {
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:c53e37f7-320c-4992-a272-bf26ff79063c")
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        transferManager1 = AWSS3TransferManager.defaultS3TransferManager()
        return modelSingletonGlobal
    }
    
    func userPrivacySetting() -> FriendsPrivacy {
        let value = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UsersFriendsPreference) as? Int ?? FriendsPrivacy.Everyone.rawValue
        switch value {
        case FriendsPrivacy.Friends.rawValue:
            return .Friends
        case FriendsPrivacy.FriendsOfFriends.rawValue:
            return .FriendsOfFriends
        case FriendsPrivacy.Everyone.rawValue:
            return .Everyone
        default:
            assertionFailure("Friends Privacy is not set to a corrrect value")
            return .Everyone
        }
    }
    
    let opQueue = OperationQueue()
    func getPeruzeItems(presentationContext: UIViewController, completion: (Void -> Void) = {}) {
        //In most cases, we want to get the location
        let getLocationOp = LocationOperation(accuracy: locationAccuracy) { (location) -> Void in
            self.performItemOperationWithLocation(location, presentationContext: presentationContext, completion: completion)
        }
        opQueue.addOperation(getLocationOp)
    }
    //helper function for above function
    private func performItemOperationWithLocation(location: CLLocation?, presentationContext: UIViewController, completion: (Void -> Void)) {
        
        let getItems = GetPeruzeItemOperation(
            presentationContext: presentationContext,
            location: location,
            context: managedConcurrentObjectContext,
            database: self.publicDB
        )
        getItems.completionBlock = completion
        opQueue.addOperation(getItems)
    }
    
    func performLogout() {
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "LastFetchTaggagleFriendsDate")
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "keyFetchedUserProfile")
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "firstTimeChatRefresh")
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "oneTimeCallForItems")
        NSUserDefaults.standardUserDefaults().synchronize()
        self.deleteAllLocalData()
        FBSDKAccessToken.setCurrentAccessToken(nil)
        FBSDKLoginManager().logOut()
        Model.sharedInstance().deleteAllSubscription()
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: UniversalConstants.kSetSubscriptions)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func deleteAllLocalData() {
        //        let context = NSManagedObjectContext.MR_context()
        var allData = Item.MR_findAllInContext(managedConcurrentObjectContext)
        for data in allData {
            managedConcurrentObjectContext.deleteObject(data as! NSManagedObject)
        }
        allData = Exchange.MR_findAllInContext(managedConcurrentObjectContext)
        for data in allData {
            managedConcurrentObjectContext.deleteObject(data as! NSManagedObject)
        }
        allData = Review.MR_findAllInContext(managedConcurrentObjectContext)
        for data in allData {
            managedConcurrentObjectContext.deleteObject(data as! NSManagedObject)
        }
        allData = TaggableFriend.MR_findAllInContext(managedConcurrentObjectContext)
        for data in allData {
            managedConcurrentObjectContext.deleteObject(data as! NSManagedObject)
        }
        allData = Message.MR_findAllInContext(managedConcurrentObjectContext)
        for data in allData {
            managedConcurrentObjectContext.deleteObject(data as! NSManagedObject)
        }
        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
    }
    
    //MARK: - Profile Setup
    
    func fetchMyMinimumProfileWithCompletion(presentationContext: UIViewController, completion: ((Person?, NSError?) -> Void)) {
        let fetchMyProfileOp = GetCurrentUserOperation(presentationContext: presentationContext, database: publicDB)
        fetchMyProfileOp.addCondition(CloudContainerCondition(container: CKContainer.defaultContainer()))
        fetchMyProfileOp
        let blockCompletionOp = BlockOperation { () -> Void in
            let fetchedPerson: Person? = Person.MR_findFirstByAttribute("me", withValue: true)
            completion(fetchedPerson, nil)
        }
        blockCompletionOp.addDependency(fetchMyProfileOp)
        OperationQueue.mainQueue().addOperations([fetchMyProfileOp, blockCompletionOp], waitUntilFinished: false)
    }
    
    //Get friends of friends
    func getMutualFriendsWithMyFriends() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let friendsIds : NSArray = defaults.objectForKey("kFriends") as! NSArray
        let set = Set(friendsIds as! [String])
        for friendsId in set {
            getFriendsFor(friendsId)
        }
    }
    
    func getFriendsFor(id : String) {
        self.friendsRecords.removeAllObjects()
        var predicate =  NSPredicate(format: "(FacebookID == %@) ", argumentArray: [id])
        loadFriend(predicate, finishBlock: { friendsRecords in
            if friendsRecords.count > 0 {
//                self.friendsRecords.addObjectsFromArray(friendsRecords.valueForKey("FriendsFacebookIDs") as! [AnyObject])
            }
            predicate =  NSPredicate(format: "(FriendsFacebookIDs == %@) ", argumentArray: [id])
            self.loadFriend(predicate, finishBlock: { friendsRecords in
//                self.friendsRecords.addObjectsFromArray(friendsRecords.valueForKey("FacebookID") as! [AnyObject])
            })
        })
    }
                    
    func loadFriend(predicate : NSPredicate , finishBlock:NSArray -> Void) {
        
        //        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
        //        query.sortDescriptors = [sort]
        let operation = CKQueryOperation(query: query)
        //        operation.desiredKeys = ["genre", "comments"]
        operation.resultsLimit = 5000
        let friendsRecords: NSMutableArray = []
        operation.recordFetchedBlock = { (record) in
            logw("\(record)")
//            friendsRecords.addObject(record)
//            self.saveFriendWith((record.objectForKey("FacebookID") as? String)! , friendsFacebookIDs: (record.objectForKey("FriendsFacebookIDs") as? String)!)
            let localFriend = Friend.MR_findFirstOrCreateByAttribute("recordIDName",  withValue: record.recordID.recordName, inContext: managedConcurrentObjectContext)
            
            if let facebookID = record.objectForKey("FacebookID") as? String {
                localFriend.facebookID = facebookID
            }
            if let friendsFacebookIDs = record.objectForKey("FriendsFacebookIDs") as? String {
                localFriend.friendsFacebookIDs = friendsFacebookIDs
            }
            managedConcurrentObjectContext.MR_saveToPersistentStoreWithCompletion(nil)
        }
        
        operation.queryCompletionBlock = { (cursor, error) -> Void in
            finishBlock(friendsRecords)
        }
        let database: CKDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //                saveItemRecordOp.qualityOfService = NSQualityOfService()
        database.addOperation(operation)
    }
    //Save friend in local DB
    func saveFriendWith(facebookID : String, friendsFacebookIDs: String) {
            
        let localFriend = Friend.MR_findFirstOrCreateByAttribute("recordIDName",  withValue: facebookID, inContext: managedConcurrentObjectContext)
        localFriend.friendsFacebookIDs = friendsFacebookIDs
        managedConcurrentObjectContext.MR_saveToPersistentStoreWithCompletion(nil)
    }
    
    func getMutualFriendsFromLocal(owner: NSManagedObject!, context: NSManagedObjectContext!) -> NSMutableSet {
        if owner == nil{
            return []
        }
        if let fbId = owner.valueForKey("facebookID") as? String {
            var predicate = NSPredicate(format: "facebookID == %@", fbId)
            let otherUserFriends = Friend.MR_findAllWithPredicate(predicate)
            let otherUserFriendsIDs:NSMutableArray = []
            for id in otherUserFriends{
                otherUserFriendsIDs.addObject(id.valueForKey("friendsFacebookIDs")!)
            }
            
            let me = Person.MR_findFirstByAttribute("me", withValue: true)
            predicate = NSPredicate(format: "facebookID == %@", me.valueForKey("facebookID") as! String)
            let myFriends = Friend.MR_findAllWithPredicate(predicate)
            let myFriendsIDs:NSMutableArray = []
            for id in myFriends{
                myFriendsIDs.addObject(id.valueForKey("friendsFacebookIDs")!)
            }
            
            //        let mutualFriendIds = Set(arrayLiteral: myFriendsIDs).intersect(Set(arrayLiteral: otherUserFriendsIDs))
            let mutualFriends: NSMutableSet = []
            for id in myFriendsIDs{
                if otherUserFriendsIDs.containsObject(id){
                    mutualFriends.addObject(id)
                }
            }
            var count = 0
            let mutualFriendsModified: NSMutableSet = []
            while count < mutualFriends.count {
                if Person.MR_findFirstByAttribute("facebookID", withValue: mutualFriends.allObjects[count] as! String, inContext: context) != nil {
                    mutualFriendsModified.addObject(mutualFriends.allObjects[count])
                } else {
//                    findPersonByFacebookID(mutualFriends.allObjects[count] as! String)
                }
                count++
            }
            context.MR_saveToPersistentStoreAndWait()
            owner.setValue(mutualFriendsModified.count , forKey: "mutualFriends")
            
            return mutualFriendsModified
        }
        return []
    }
    
    func getMutualFriendsFromFb(person: NSManagedObject, context_: NSManagedObjectContext, completionBlock: (Void -> Void) = { }) {
        let fbId = person.valueForKey("facebookID") as? String
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context_)
        if fbId != nil || me.valueForKey("recordIDName") as! String != person.valueForKey("recordIDName") as! String {
            
            let fieldsDict = ["fields":"context.fields(mutual_friends.fields(name,id,picture,first_name))"]//,"appsecret_proof":"0d9888220cc9669ee500c1361e41be0e"]
            let request = FBSDKGraphRequest(graphPath:fbId, parameters: fieldsDict)
            request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                if error == nil {
                    logw("Mutual Friends with \(person.valueForKey("firstName")!) \(person.valueForKey("lastName")!) are : \(result)")
                    
                    if let mutualFriends = result.valueForKey("context")!.valueForKey("mutual_friends") {
                        let resultsArray = mutualFriends.valueForKey("data") as! NSArray
                        person.setValue(resultsArray.count, forKey: "mutualFriends")
                    }
                } else {
                    logw("Mutual Friends error: \(error)")
                    person.setValue(0, forKey: "mutualFriends")
                }
                dispatch_async(dispatch_get_main_queue()) {
                    context_.MR_saveToPersistentStoreAndWait()
                    completionBlock()
                }
            }
        } else {
            person.setValue(0, forKey: "mutualFriends")
            dispatch_async(dispatch_get_main_queue()) {
                context_.MR_saveToPersistentStoreAndWait()
                completionBlock()
            }
        }
    }
    
    func getTaggableFriends() {
         let request = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5000", parameters: ["fields":"name,id,picture.fields(url),first_name,last_name,context"]);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Taggable Friends are : \(result)")
                
                var resultsArray = result.valueForKey("data") as! NSArray
                resultsArray = resultsArray.sort { (element1, element2) -> Bool in
                    return (element1.valueForKey("name") as! String) < (element2.valueForKey("name") as! String)
                }
                
                var nameArray = [String]()
                for var result in resultsArray {
                    nameArray.append(result.valueForKey("first_name") as! String)
                }
                NSUserDefaults.standardUserDefaults().setValue(nameArray, forKey: "kFriends")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                let me = Person.MR_findFirstByAttribute("me", withValue: true)
                
                for friendData in resultsArray {
                    let context = NSManagedObjectContext.MR_context()
                    let taggableFriendLocal = TaggableFriend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friendData.valueForKey("id"), inContext: context)
                    taggableFriendLocal.setValue(friendData.valueForKey("first_name"), forKey: "firstName")
                    taggableFriendLocal.setValue(friendData.valueForKey("last_name"), forKey: "lastName")
                    taggableFriendLocal.setValue(friendData.valueForKey("picture")!.valueForKey("data")!.valueForKey("url"), forKey: "imageUrl")
                    taggableFriendLocal.setValue(me.valueForKey("facebookID"), forKey: "facebookID")
                    context.MR_saveToPersistentStoreAndWait()
                }
                self.postTaggableFriendToCloud()
            } else {
                logw("Error Getting Friends \(error)");
            }
        }
    }
    
    func postTaggableFriendToCloud() {
         let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "facebookID == %@", me.valueForKey("facebookID") as! String)
        let context = NSManagedObjectContext.MR_context()
        let allTaggableFriends = TaggableFriend.MR_findAllWithPredicate(predicate, inContext: context)
        
        var allTaggableFriendsRecord = [CKRecord]()
        for friend in allTaggableFriends {
            let taggableFriend = CKRecord(recordType: RecordTypes.TaggableFriends)
            taggableFriend.setObject(friend.valueForKey("facebookID") as? String, forKey: "FacebookID")
            taggableFriend.setObject(friend.valueForKey("firstName") as? String, forKey: "FirstName")
            taggableFriend.setObject(friend.valueForKey("lastName") as? String, forKey: "LastName")
            taggableFriend.setObject(friend.valueForKey("imageUrl") as? String, forKey: "ImageUrl")
            allTaggableFriendsRecord.append(taggableFriend)
            
            let postTaggableOperation = CKModifyRecordsOperation(recordsToSave: [taggableFriend], recordIDsToDelete: nil)
            postTaggableOperation.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
                if operationError != nil {
                    return
                }
                friend.setValue(savedRecords?.first?.recordID.recordName, forKey: "recordIDName")
                context.MR_saveToPersistentStoreAndWait()
            }
            CKContainer.defaultContainer().publicCloudDatabase.addOperation(postTaggableOperation)
        }
    }
    
    func deleteTaggablefriendsForPerson(person: NSManagedObject = Person.MR_findFirstByAttribute("me", withValue: true), completionBlock: (Void -> Void) = {}) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) PERSON: \(person)")
        let facebookID = person.valueForKey("facebookID")
        let predicate = NSPredicate(format: "facebookID == %@", facebookID as! String)
        let context = NSManagedObjectContext.MR_context()
        let allTaggableFriends = TaggableFriend.MR_findAllWithPredicate(predicate, inContext: context)
        for friend in allTaggableFriends {
            let taggableFriend = CKRecordID(recordName: friend.valueForKey("recordIDName") as! String)
            
            let postTaggableOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [taggableFriend])
            postTaggableOperation.modifyRecordsCompletionBlock = { (savedRecords, _, operationError) -> Void in
                context.deleteObject(friend as! NSManagedObject)
                context.MR_saveToPersistentStoreAndWait()
                if allTaggableFriends[allTaggableFriends.count - 1] as! NSManagedObject == friend as! NSManagedObject {
                    completionBlock()
                }
            }
            CKContainer.defaultContainer().publicCloudDatabase.addOperation(postTaggableOperation)
        }
        if allTaggableFriends.count == 0 {
            completionBlock()
        }
        context.MR_saveToPersistentStoreAndWait()
    }
    
    func fetchTaggleFriendsRecordFromCloud(person: NSManagedObject = Person.MR_findFirstByAttribute("me", withValue: true), isMe: Bool = true, completionBlock: (Void -> Void) = {}) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) ISME: \(isMe), PERSON: \(person)")
        
        let predicate = NSPredicate(format: "FacebookID == %@", person.valueForKey("facebookID") as! String)
        let taggableFriendsQuery = CKQuery(recordType: RecordTypes.TaggableFriends, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate]))
        let taggableFriendsQueryOp = CKQueryOperation(query: taggableFriendsQuery)
        
        
        //Add the messages to the database and save the context
        taggableFriendsQueryOp.recordFetchedBlock = { (record: CKRecord!) -> Void in
            
            logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) TAGGABLEFRIENDS QUERY OP RECORD FETCH BLOCK")
            let context = NSManagedObjectContext.MR_context()
            let friend = TaggableFriend.MR_findFirstOrCreateByAttribute("recordIDName",
                withValue: record.recordID.recordName, inContext: context)
            
            if let facebookID = record.objectForKey("FacebookID") as? String {
                friend.setValue(facebookID, forKey: "facebookID")
            }
            if let firstName = record.objectForKey("FirstName") as? String {
                friend.setValue(firstName, forKey: "firstName")
                if NSUserDefaults.standardUserDefaults().valueForKey("friendsOfFriendsIds") == nil {
                   NSUserDefaults.standardUserDefaults().setValue([firstName], forKey: "friendsOfFriendsIds")
                    NSUserDefaults.standardUserDefaults().synchronize()
                } else {
                    if var storedNames = NSUserDefaults.standardUserDefaults().valueForKey("friendsOfFriendsIds") as? [String] {
                        storedNames.append(firstName)
                        NSUserDefaults.standardUserDefaults().setValue(storedNames, forKey: "friendsOfFriendsIds")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
                }
            }
            if let lastName = record.objectForKey("LastName") as? String {
                friend.setValue(lastName, forKey: "lastName")
            }
            if let imageUrl = record.objectForKey("ImageUrl") as? String {
                friend.setValue(imageUrl, forKey: "imageUrl")
            }
            context.MR_saveToPersistentStoreAndWait()
        }
        
        taggableFriendsQueryOp.completionBlock = {
            if isMe == true {
                self.deleteTaggablefriendsForPerson(person, completionBlock: {
                    completionBlock()
                })
            } else {
                completionBlock()
            }
        }
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(taggableFriendsQueryOp)
    }
    
    func getTaggbleFriendsFromCloudAndMatch(person: NSManagedObject, context: NSManagedObjectContext = managedConcurrentObjectContext, completionBlock: (Int -> Void) = {_ in }) {
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        if me.valueForKey("recordIDName") as! String != person.valueForKey("recordIDName") as! String {
            dispatch_async(dispatch_get_main_queue()) {
                Model.sharedInstance().fetchTaggleFriendsRecordFromCloud(person, isMe: false, completionBlock: {
                    let context = NSManagedObjectContext.MR_context()
                    self.refreshTaggableFriendsFromLocal(person, context: context, completionBlock: { count in
                        completionBlock(count)
                    })
                })
            }
        }
    }
    
    func refreshTaggableFriendsFromLocal(person: NSManagedObject, context: NSManagedObjectContext = managedConcurrentObjectContext, completionBlock: (Int -> Void) = {_ in }) {
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let myTaggableFriends = TaggableFriend.MR_findAllWithPredicate(NSPredicate(format: "facebookID == %@", me.valueForKey("facebookID") as! String), inContext: context)
        if person.valueForKey("facebookID") == nil {
            return
        }
        let otherTaggableFriends = TaggableFriend.MR_findAllWithPredicate(NSPredicate(format: "facebookID == %@", person.valueForKey("facebookID") as! String), inContext: context)
        
        let commonFriends: NSMutableArray = []
        let nameArray: NSMutableArray = []
        
        for myFriend in myTaggableFriends {
            let currentName = "\(myFriend.valueForKey("firstName") as! String) \(myFriend.valueForKey("lastName") as! String)"
            for otherUserfriend in otherTaggableFriends {
                if myFriend.valueForKey("firstName") as! String == otherUserfriend.valueForKey("firstName") as! String &&
                    myFriend.valueForKey("lastName") as! String == otherUserfriend.valueForKey("lastName") as! String && !nameArray.containsObject(currentName) {
                        
                        commonFriends.addObject(myFriend)
                        nameArray.addObject(currentName)
                }
            }
        }
        var taggableFriendsData = [FriendsDataAndProfilePic]()
        for friend in commonFriends {
            let friendDict = [
                "name":"\(friend.valueForKey("firstName")!) \(friend.valueForKey("lastName")!)",
                "first_name":"\(friend.valueForKey("firstName")!)",
                "last_name":"\(friend.valueForKey("lastName")!)"]
            
            let newFriendData = FriendsDataAndProfilePic(friendData: friendDict, profileImageUrl: friend.valueForKey("imageUrl") as! String)
            taggableFriendsData.append(newFriendData)
        }
        person.setValue(taggableFriendsData.count, forKey: "mutualFriends")
        context.MR_saveToPersistentStoreAndWait()
        completionBlock(taggableFriendsData.count)
    }
    
    //MARK: Fetch record
    
    func fetchItemWithRecord(recordID: CKRecordID, shouldReloadScreen: Bool = true, completionBlock: (Bool -> Void) = {Bool -> Void in return false}) -> Void
    {
        self.publicDB.fetchRecordWithID(recordID,
            completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        //                        self.notifyUser("Fetch Error", message:
                        //                            err.localizedDescription)
                        logw("Error while fetching Item : \(err)")
                        completionBlock(false)
                    }
                } else {
                    if record?.recordType == RecordTypes.Item {
                        let context = NSManagedObjectContext.MR_context()
                        var isItemPresentLocally = true
                        if Item.MR_findFirstByAttribute("recordIDName",
                            withValue: record!.recordID.recordName, inContext: context) == nil {
                            isItemPresentLocally = false
                        }
                        let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.recordID.recordName, inContext: context)
                        
                        if isItemPresentLocally == false {
                            localUpload.setValue(NSDate(), forKey: "dateOfDownload")
                        }
                        
                        localUpload.setValue(record!.recordID.recordName, forKey: "recordIDName")
                        
                        let ownerRecordIDName = record!.creatorUserRecordID!.recordName
                        
                        if ownerRecordIDName == "__defaultOwner__" {
                            let owner = Person.MR_findFirstByAttribute("me",
                                withValue: true,
                                inContext: context)
                            localUpload.setValue(owner, forKey: "owner")
                        } else {
                            let owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: ownerRecordIDName,
                                inContext: context)
                            localUpload.setValue(owner, forKey: "owner")
                            let getOwnerOperation = GetPersonOperation(recordID: CKRecordID(recordName: ownerRecordIDName), database: CKContainer.defaultContainer().publicCloudDatabase)
                            OperationQueue().addOperation(getOwnerOperation)
                        }
                        
                        if let title = record!.objectForKey("Title") as? String {
                            localUpload.setValue(title, forKey: "title")
                        }
                        
                        if let detail = record!.objectForKey("Description") as? String {
                            localUpload.setValue(detail, forKey: "detail")
                        }
                        
                        if let ownerFacebookID = record!.objectForKey("OwnerFacebookID") as? String {
                            localUpload.setValue(ownerFacebookID, forKey: "ownerFacebookID")
                        } else {
                            localUpload.setValue("noId", forKey: "ownerFacebookID")
                        }
                        
//                        if let imageAsset = record!.objectForKey("Image") as? CKAsset {
//                            let imageData = NSData(contentsOfURL: imageAsset.fileURL)
//                            localUpload.setValue(imageData, forKey: "image")
//                        }
                        
                        if let imageUrl = record!.objectForKey("ImageUrl") as? String {
                            localUpload.setValue(imageUrl, forKey: "imageUrl")
                        }
//                        if let imageUrl = record!.objectForKey("ImageUrl") as? String {
//                            let downloadingFilePath = NSTemporaryDirectory()
//                            let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrl, downloadingFilePath: downloadingFilePath)
//                            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//                            let task = transferManager.download(downloadRequest)
//                            task.continueWithBlock({ (task) -> AnyObject? in
//                                if task.error != nil {
//                                    logw("GetItemOperation image download failed with error: \(task.error!)")
//                                } else {
//                                    dispatch_async(dispatch_get_main_queue()) {
//                                        let fileUrl = task.result!.valueForKey("body")!
//                                        let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                                        localUpload.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                                        context.MR_saveToPersistentStoreAndWait()
//                                        NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruseItemMainScreen", object: nil)
//                                        completionBlock(true)
//                                    }
//                                }
//                                return nil
//                            })
//                        }
                        
                        if let itemLocation = record!.objectForKey("Location") as? CLLocation {//(latitude: itemLat.doubleValue, longitude: itemLong.doubleValue)
                            
                            if let latitude : Double = Double(itemLocation.coordinate.latitude) {
                                localUpload.setValue(latitude, forKey: "latitude")
                            }
                            
                            if let longitude : Double = Double(itemLocation.coordinate.longitude) {
                                localUpload.setValue(longitude, forKey: "longitude")
                            }
                        }
                        
                        if let isDelete = record!.objectForKey("IsDeleted") as? Int {
                            localUpload.setValue(isDelete, forKey: "isDelete")
                        }
                        
                        if localUpload.hasRequested != "yes" {
                            localUpload.setValue("no", forKey: "hasRequested")
                        }
                        
                        //save the context
                        context.MR_saveToPersistentStoreAndWait()
                
                        if shouldReloadScreen == true {
                            NSNotificationCenter.defaultCenter().postNotificationName("justReloadPeruseItemMainScreen", object: nil,userInfo: ["shouldShuffle":"yes"])
                        } else {
                            NSNotificationCenter.defaultCenter().postNotificationName("justReloadPeruseItemMainScreen", object: nil)
                        }
                        completionBlock(true)
                    }
                    completionBlock(false)
                }
            }))
    }
    
    func fetchExchangeWithRecord(recordID: CKRecordID, message: String, badgeCount: Int = 0) -> Void
    {
        self.publicDB.fetchRecordWithID(recordID,
            completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        //                        self.notifyUser("Fetch Error", message:
                        //                            err.localizedDescription)
                        logw("Error while fetching Exchange : \(err)")
                    }
                } else {
                    if record?.recordType == RecordTypes.Exchange {
                        let context = NSManagedObjectContext.MR_context()
                        let requestingPerson = Person.MR_findFirstOrCreateByAttribute("me", withValue: true,inContext: context)
                        
                        let localExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.recordID.recordName,
                            inContext: context)
                        
                        //set creator
                        if record!.creatorUserRecordID!.recordName == "__defaultOwner__" {
                            let creator = Person.MR_findFirstOrCreateByAttribute("me",
                                withValue: true,
                                inContext: context)
                            localExchange.setValue(creator, forKey: "creator")
                        } else {
                            let creator = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: record!.creatorUserRecordID?.recordName,
                                inContext: context)
                            localExchange.setValue(creator, forKey: "creator")
                        }
                        
                        //set exchange status
                        if let newExchangeStatus = record!.objectForKey("ExchangeStatus") as? Int {
                            localExchange.setValue(NSNumber(integer: newExchangeStatus), forKey: "status")
                        }
                        
                        //set datedateOfLatestChat
                        if let newDate = record!.objectForKey("DateExchanged") as? NSDate {
                            let date = localExchange.valueForKey("date") as? NSDate
                            localExchange.setValue((date ?? newDate), forKey: "date")
                            localExchange.setValue((date ?? newDate), forKey: "dateOfLatestChat")
                        }
                        
                        var itemOffered: NSManagedObject!
                        //set item offered
                        if let itemOfferedReference = record!.objectForKey("OfferedItem") as? CKReference {
                            itemOffered = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: itemOfferedReference.recordID.recordName,
                                inContext: context)
                            itemOffered.setValue("yes", forKey: "hasRequested")
                            if localExchange.valueForKey("status") as! Int == 2 ||
                                localExchange.valueForKey("status") as! Int == 4 {
                                    
//                                    let itemOfferedOwner = itemOffered.valueForKey("owner")
//                                    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
//                                    if itemOfferedOwner!.valueForKey("recordIDName") as! String != me.valueForKey("recordIDName") as! String && itemOfferedOwner!.valueForKey("recordIDName") as! String != "__defaultOwner__" {
//                                        
//                                        let predicate = NSPredicate(format: "itemOffered.recordIDName == %@ OR itemRequested.recordIDName == %@",itemOffered.valueForKey("recordIDName") as! String, itemOffered.valueForKey("recordIDName") as! String)
//                                        let exchanges = Exchange.MR_findAllWithPredicate(predicate)
//                                        if exchanges.count <= 1 {
//                                            itemOffered.setValue("no", forKey: "hasRequested")
//                                        }
//                                    }
                            }
                            localExchange.setValue(itemOffered, forKey: "itemOffered")
                        }
                        
                        var itemRequested: NSManagedObject!
                        var itemRequestedRecordID: String!
                        //set item requested
                        if let itemRequestedReference = record!.objectForKey("RequestedItem") as? CKReference {
                            itemRequested = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: itemRequestedReference.recordID.recordName,
                                inContext: context)
                            itemRequestedRecordID = itemRequested.valueForKey("recordIDName") as! String
                            itemRequested.setValue("no", forKey: "hasRequested")
                            if localExchange.valueForKey("status") as! Int == 2 ||
                                localExchange.valueForKey("status") as! Int == 4{
//                                    let itemOfferedOwner = itemRequested.valueForKey("owner")
//                                    let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: context)
//                                    if itemOfferedOwner!.valueForKey("recordIDName") as! String != me.valueForKey("recordIDName") as! String && itemOfferedOwner!.valueForKey("recordIDName") as! String != "__defaultOwner__" {
//                                        
//                                        let predicate = NSPredicate(format: "itemOffered.recordIDName == %@ OR itemRequested.recordIDName == %@",itemRequested.valueForKey("recordIDName") as! String, itemRequested.valueForKey("recordIDName") as! String)
//                                        let exchanges = Exchange.MR_findAllWithPredicate(predicate)
//                                        if exchanges.count <= 1 {
//                                            itemRequested.setValue("no", forKey: "hasRequested")
//                                        }
//                                    }
                            }
                            localExchange.setValue(itemRequested, forKey: "itemRequested")
                        }
                        
                        
                        
                        //add this exchange to the requesting user's exchanges
                        let currentExchanges = requestingPerson.valueForKey("exchanges") as! NSSet
                        
                        let set = currentExchanges.setByAddingObject(localExchange)
                        //                    requestingPerson.setValue(set as NSSet, forKey: "exchanges")
                        
                        let localExchangeStatus: NSNumber
                        if let status = localExchange.valueForKey("status") as? NSNumber {
                            localExchangeStatus = status
                        } else {
                            localExchangeStatus = -1
                        }
                        
                        //save the context
                        context.MR_saveToPersistentStoreAndWait()
                        
                        
                        //Fetching offered and requested items
                        var isRequestedItemPresentLocally = true
                        
                        if itemRequested.valueForKey("recordIDName") == nil || itemRequested.valueForKey("title") == nil || itemRequested.valueForKey("image") == nil{
                            isRequestedItemPresentLocally = false
                        }
                        
                        if itemOffered.valueForKey("recordIDName") == nil || itemOffered.valueForKey("title") == nil || itemOffered.valueForKey("image") == nil {
                            self.fetchItemWithRecord(CKRecordID(recordName: itemOffered.valueForKey("recordIDName") as! String), shouldReloadScreen: false, completionBlock: {
                                (isOfferedItemFetchedSuccessfully : Bool) in
                                if isOfferedItemFetchedSuccessfully == true {
                                    
                                    //After first success.... Fetch second item
                                    
                                    if isRequestedItemPresentLocally == false {
                                        self.fetchItemWithRecord(CKRecordID(recordName: itemRequestedRecordID), shouldReloadScreen: false, completionBlock: {
                                            (isRequestedItemFetchedSuccessfully : Bool) in
                                            if isRequestedItemFetchedSuccessfully == true {
                                                
                                                self.sendLocalNotificationWith(message, localExchangeStatus: localExchangeStatus, badgeCount: badgeCount)
                                                
                                            }
                                        })
                                    } else {
                                        self.sendLocalNotificationWith(message, localExchangeStatus: localExchangeStatus, badgeCount: badgeCount)
                                    }
                                }
                            })
                        } else {
                            if isRequestedItemPresentLocally == false {
                                self.fetchItemWithRecord(CKRecordID(recordName: itemRequestedRecordID), shouldReloadScreen: false, completionBlock: {
                                    (isRequestedItemFetchedSuccessfully : Bool) in
                                    if isRequestedItemFetchedSuccessfully == true {
                                        
                                        self.sendLocalNotificationWith(message, localExchangeStatus: localExchangeStatus, badgeCount: badgeCount)
                                        
                                    }
                                })
                            } else {
                                self.sendLocalNotificationWith(message, localExchangeStatus: localExchangeStatus, badgeCount: badgeCount)
                            }
                        }
                    }
                }
            }))
    }
    
    func sendLocalNotificationWith(message: String, localExchangeStatus: NSNumber, badgeCount: Int) {
        //Fire local notification for updation
        if message == NotificationCategoryMessages.NewOfferMessage {
            //                            if NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") != nil && NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") as! String == "yes"{
            if localExchangeStatus == 0 {
                NSNotificationCenter.defaultCenter().postNotificationName("getRequestedExchange", object: nil)
                if badgeCount > 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName("setRequestBadge", object: nil, userInfo: ["badgeCount": badgeCount])
                }
            }
            //                            }
        }
        if message == NotificationCategoryMessages.UpdateOfferMessage {
            if localExchangeStatus == 2 || localExchangeStatus == 4 {
                NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruseItemMainScreen", object: nil)
            }
        }
        if message == NotificationCategoryMessages.AcceptedOfferMessage {
            if localExchangeStatus == 1 {
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.LNRefreshChatScreenForUpdatedExchanges, object: nil)
                if badgeCount > 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName("setAcceptedExchangesBadge", object: nil, userInfo: ["badgeCount": badgeCount])
                }
            }
        }
    }
    
    func fetchChatWithRecord(recordID: CKRecordID, badgeCount: Int = 0) -> Void
    {   self.publicDB = CKContainer.defaultContainer().publicCloudDatabase
        self.publicDB.fetchRecordWithID(recordID,
            completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        //                        self.notifyUser("Fetch Error", message:
                        //                            err.localizedDescription)
                        logw("Error while fetching Exchange : \(err)")
                    }
                } else {
                    if record?.recordType == RecordTypes.Message {
                        let localMessage = Message.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.recordID.recordName, inContext: managedConcurrentObjectContext)
                        
                        if let messageText = record!.objectForKey("Text") as? String {
                            localMessage.setValue(messageText, forKey: "text")
                        }
                        
//                        if let messageImage = record!.objectForKey("Image") as? CKAsset {
//                            localMessage.setValue(NSData(contentsOfURL: messageImage.fileURL), forKey: "image")
//                        }
                        
                        localMessage.setValue(record!.objectForKey("Date") as? NSDate, forKey: "date")
                        
                        var exchangeRecordIDName = ""
                        if let exchange = record!.objectForKey("Exchange") as? CKReference {
                            let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: exchange.recordID.recordName,
                                inContext: managedConcurrentObjectContext)
                            messageExchange.setValue(record!.modificationDate, forKey: "dateOfLatestChat")
                            localMessage.setValue(messageExchange, forKey: "exchange")
                            exchangeRecordIDName = exchange.recordID.recordName
                        }
                        
                        let sender = Person.MR_findFirstOrCreateByAttribute("me",
                            withValue: true,
                            inContext: managedConcurrentObjectContext)
                        if (record!.creatorUserRecordID?.recordName == "__defaultOwner__") ||
                            (record!.creatorUserRecordID?.recordName == sender?.valueForKey("recordIDName") as? String) {
                                localMessage.setValue(sender, forKey: "sender")
                        } else {
                            let sender = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: record!.creatorUserRecordID?.recordName,
                                inContext:managedConcurrentObjectContext)
                            localMessage.setValue(sender, forKey: "sender")
                        }
                        
                        //save the context
                        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                        NSNotificationCenter.defaultCenter().postNotificationName("NewChat", object: nil, userInfo: ["exchangeRecordIDName": exchangeRecordIDName])
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.LNRefreshChatScreenForUpdatedExchanges, object: nil)
                    if badgeCount > 0 {
                        NSNotificationCenter.defaultCenter().postNotificationName("setAcceptedExchangesBadge", object: nil, userInfo: ["badgeCount": badgeCount])
                    }
                }
            }))
    }
    
    func fetchUserWithRecord(recordID: CKRecordID) {
        self.publicDB = CKContainer.defaultContainer().publicCloudDatabase
        self.publicDB.fetchRecordWithID(recordID ,completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        logw("Error while fetching User : \(err)")
                    }
                } else {
                    if record?.recordType == RecordTypes.UsersStatus {
                        logw ("Fetch user ")
                        var localPerson = Person.MR_findFirstByAttribute("recordIDName",
                            withValue: record!.valueForKey("UserRecordIDName")!.recordID.recordName, inContext: managedConcurrentObjectContext)
                        if localPerson == nil {
                            localPerson = Person.MR_findFirstByAttribute("recordIDName",
                                withValue: "__defaultOwner__", inContext: managedConcurrentObjectContext)
                        }
                        if localPerson != nil {
                            if let isDelete = record?.valueForKey("IsDeleted") as? Int{
                                localPerson.setValue(isDelete , forKey: "isDelete")
                            }
                        }
//                        if let personFbId = record!.objectForKey("FacebookID") as? String {
//                            localPerson.setValue(personFbId, forKey: "facebookID")
//                            
//                            let predicate = NSPredicate(format: "FacebookID == %@", record!.objectForKey("FacebookID") as! String)
//                            let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
//                            let context = NSManagedObjectContext()
//                            CKContainer.defaultContainer().publicCloudDatabase.performQuery(query, inZoneWithID: nil, completionHandler: {
//                                (friends: [CKRecord]?, error) -> Void in
//                                logw("Fetch User by notification Friends block")
//                                for friend in friends! {
//                                    let localFriendRecord = Friend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friend.recordID.recordName, inContext: context)
//                                    if let facebookID = friend.objectForKey("FacebookID") {
//                                        localFriendRecord.setValue(facebookID, forKey: "facebookID")
//                                    }
//                                    if let friendsFacebookID = friend.objectForKey("FriendsFacebookIDs") {
//                                        localFriendRecord.setValue(friendsFacebookID, forKey: "friendsFacebookIDs")
//                                    }
//                                    let mutualFriends = Model.sharedInstance().getMutualFriendsFromLocal(localPerson, context: context)
//                                    localPerson.setValue(mutualFriends.count, forKey: "mutualFriends")
//                                }
//                                context.MR_saveToPersistentStoreAndWait()
//                            })
//                        }
//                        if let firstName = record!.objectForKey("FirstName") as? String {
//                            localPerson.setValue(firstName, forKey: "firstName")
//                        }
//                        if let lastName = record!.objectForKey("LastName") as? String {
//                            localPerson.setValue(lastName, forKey: "lastName")
//                        }
//                        
//                        if let personImage = record!.objectForKey("Image") as? CKAsset {
//                            localPerson.setValue(NSData(contentsOfURL: personImage.fileURL), forKey: "image")
//                        }
//                        
//                        if let isDelete = record!.objectForKey("IsDeleted") as? Int {
//                            localPerson.setValue(isDelete, forKey: "isDelete")
//                        }
//                        
//                        let me = Person.MR_findFirstByAttribute("me", withValue: true)
//                        if me.recordIDName == record!.recordID.recordName {
//                            localPerson.setValue(true, forKey: "me")
//                        } else {
//                            localPerson.setValue(false, forKey: "me")
//                        }
                        
                        //check for favorites
//                        if let favoriteReferences = record!.objectForKey("FavoriteItems") as? [CKReference] {
//                            let favorites = favoriteReferences.map {
//                                Item.MR_findFirstOrCreateByAttribute("recordIDName",
//                                    withValue: $0.recordID.recordName , inContext: managedConcurrentObjectContext)
//                            }
//                            let favoritesSet = NSSet(array: favorites)
//                            localPerson.setValue(favoritesSet, forKey: "favorites")
//                        }
                        
                        //save the context
                        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.UpdateItemsOnFilterChange, object: nil)
                    }
                }
            }))
    }
    
    func fetchReviewWithRecord(recordID: CKRecordID) -> Void
    {   self.publicDB = CKContainer.defaultContainer().publicCloudDatabase
        self.publicDB.fetchRecordWithID(recordID,
            completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        //                        self.notifyUser("Fetch Error", message:
                        //                            err.localizedDescription)
                        logw("Error while fetching Exchange : \(err)")
                    }
                } else {
                    if record?.recordType == RecordTypes.Review {
                        let context = NSManagedObjectContext.MR_context()
                        let localReview = Review.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.recordID.recordName, inContext: context)
                        
                        if let detail = record!.objectForKey("Description") as? String {
                            localReview.detail = detail
                        }
                        
                        if let starRating = record!.objectForKey("StarRating") as? NSNumber {
                            localReview.starRating = starRating
                        }
                        
                        if let title = record!.objectForKey("Title") as? String {
                            localReview.title = title
                        }
                        
                        if let userBeingReviewed = record!.objectForKey("UserBeingReviewed") as? CKReference {
                            let userReviewedIDName = userBeingReviewed.recordID.recordName
                            logw(userReviewedIDName)
                            let reviewedUser = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: userReviewedIDName, inContext: context)
                            context.MR_saveToPersistentStoreAndWait()
                            localReview.userBeingReviewed = reviewedUser
                        }
                        
                        localReview.date = record!.creationDate
                        
                        if var creator = record!.creatorUserRecordID?.recordName {
                            if creator == "__defaultOwner__"{
                                creator = Person.MR_findFirstByAttribute("me",withValue: true, inContext: context).valueForKey("recordIDName") as! String
                            }
                            let reviewer = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: creator, inContext: context)
                            context.MR_saveToPersistentStoreAndWait()
                            localReview.reviewer = reviewer
                        }
                        
                        //save the context
                        context.MR_saveToPersistentStoreAndWait()
                    }
                }
            }))
    }
    
    func getAllDeleteUsers() {
        let predicate = NSPredicate(value: true)
        let getUsersQuery = CKQuery(recordType: RecordTypes.UsersStatus, predicate: predicate)
                let getAllDeletedUsersOperation = CKQueryOperation(query: getUsersQuery)
        
                //handle returned objects
                getAllDeletedUsersOperation.recordFetchedBlock = {
                    (record: CKRecord!) -> Void in
                    let person = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: record.recordID.recordName)
                    person.setValue(record.creatorUserRecordID?.recordName, forKey: "recordIDName")
                    person.setValue(record.valueForKey("IsDeleted"), forKey: "isDelete")
                    managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                }
                getAllDeletedUsersOperation.queryCompletionBlock = {
                    (cursor, error) -> Void in
        
                }
                OperationQueue().addOperation(getAllDeletedUsersOperation)
        CKContainer.defaultContainer().publicCloudDatabase.performQuery(getUsersQuery, inZoneWithID: nil) {
            (records, error) -> Void in
            for record in records! {
                logw(" \(record)")
            }
            error?.localizedDescription
        }
    }
    
    //MARK: - Subscription methods
    
    
//    - (void)unsubscribe {
//    if (self.subscribed == YES) {
//    
//    NSString *subscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey:subscriptionIDkey];
//    
//    // Create an operation to modify the subscription with the subscriptionID.
//    CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
//    modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
//    
//    // The completion block will be executed after the modify operation is executed.
//    modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
//    if (error) {
//    // In your app, handle this error beautifully.
//    NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
//    abort();
//    } else {
//    NSLog(@"Unsubscribed to Item");
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionIDkey];
//    }
//    };
//    
//    // Add the operation to the private database. The operation will be executed immediately.
//    [self.privateDatabase addOperation:modifyOperation];
//    }
//    }
    
    
    
    func deleteAndSetAllSubscriptions() {
        
        let database = CKContainer.defaultContainer().publicCloudDatabase
        database.fetchAllSubscriptionsWithCompletionHandler({subscriptions, error in
            
            for subscriptionObject in subscriptions! {
                let subscription: CKSubscription = subscriptionObject as CKSubscription
                logw("Subscription :\(subscription)")
                
                database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {subscriptionId, error in
                        logw("Subscription with id \(subscriptionId!) was removed : \(subscription.description)")
                    if subscriptions?.indexOf(subscriptionObject) == subscriptions?.count{
                        logw("Subscriptions added after deleting.")
//                        self.subscribeForNewOffer()
                    }
                })
            }
            if subscriptions?.count == 0 {
                logw("Subscriptions added with no previous subscriptions.")
//                self.subscribeForNewOffer()
            }
        })
    }
    
    func subscribeForNewOffer(shouldResumeChainOfSubscriptions: Bool = true, completionHandler: (Void -> Void) = {}) {
         
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "RequestedItemOwnerRecordIDName == %@", me.recordIDName!)
        let subscription = CKSubscription(recordType: "Exchange",
            predicate: predicate,
            options: .FiresOnRecordCreation)
        
        let notificationInfo = CKNotificationInfo()
        if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) as? String == "yes" ||
           NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) == nil {
            notificationInfo.alertBody = NotificationMessages.NewOfferMessage
            notificationInfo.shouldBadge = true
            notificationInfo.soundName = "default"
        }
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.NewOfferMessage
        }
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("NewOffer subscription failed \(err.localizedDescription)")
                } else {
                    logw("NewOffer subscription success with ID: \(returnRecord!.subscriptionID)")
                    NSUserDefaults.standardUserDefaults().setValue(returnRecord!.subscriptionID, forKey: SubscriptionIDs.NewOfferSubscriptionID)
                    NSUserDefaults.standardUserDefaults().synchronize()
//                    newOfferSubscriptionID = returnRecord!.subscriptionID
                }
                if shouldResumeChainOfSubscriptions == true {
                    self.subscribeForUpdatedOffer()
                }
                completionHandler()
            }))
    }
    
    func subscribeForUpdatedOffer() {
         
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "RequestedItemOwnerRecordIDName == %@", me.recordIDName!)
        let statusPredicate = NSPredicate(format: "ExchangeStatus != 1")
        let subscription = CKSubscription(recordType: "Exchange",
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, statusPredicate]),
            options: .FiresOnRecordUpdate)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.UpdateOfferMessage
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("UpdateOffer subscription failed \(err.localizedDescription)")
                } else {
                    logw("UpdateOffer subscription success")
                }
                self.subscribeForAcceptedOffer()
            }))
    }
    
    func subscribeForAcceptedOffer(shouldResumeChainOfSubscriptions: Bool = true, completionHandler: (Void -> Void) = {}) {
         
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "OfferedItemOwnerRecordIDName == %@", me.recordIDName!)
        let statusPredicate = NSPredicate(format: "ExchangeStatus == 1")
        let subscription = CKSubscription(recordType: "Exchange",
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, statusPredicate]),
            options: .FiresOnRecordUpdate)
        
        let notificationInfo = CKNotificationInfo()
        if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) as? String == "yes" ||
            NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) == nil {
            notificationInfo.alertBody = NotificationMessages.AcceptedOfferMessage
            notificationInfo.shouldBadge = true
            notificationInfo.soundName = "default"
        }
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.AcceptedOfferMessage
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("AcceptedOffer subscription failed \(err.localizedDescription)")
                } else {
                    logw("AcceptedOffer subscription success with ID: \(returnRecord!.subscriptionID)")
                    NSUserDefaults.standardUserDefaults().setValue(returnRecord!.subscriptionID, forKey: SubscriptionIDs.AcceptedOfferSubscriptionID)
                    NSUserDefaults.standardUserDefaults().synchronize()
//                    acceptedOfferSubscriptionID = returnRecord!.subscriptionID
                }
                if shouldResumeChainOfSubscriptions == true {
                    self.subscribeForChat()
                }
                completionHandler()
            }))
    }
    
    func subscribeForChat(shouldResumeChainOfSubscriptions: Bool = true, completionHandler: (Void -> Void) = {}) {
         let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "ReceiverRecordIDName == %@", me.recordIDName!)
        //        let predicate = NSPredicate(value: true)
        let subscription = CKSubscription(recordType: RecordTypes.Message,
            predicate: predicate,
            options: .FiresOnRecordCreation)
        
        let notificationInfo = CKNotificationInfo()
        if NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) as? String == "yes" ||
            NSUserDefaults.standardUserDefaults().valueForKey(UniversalConstants.kIsPushNotificationOn) == nil {
                notificationInfo.alertBody = NotificationMessages.NewChatMessage
                notificationInfo.shouldBadge = true
                notificationInfo.soundName = "default"
        }
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.NewChatMessage
        }
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("Chat subscription failed \(err.localizedDescription)")
                } else {
                    logw("Chat subscription success")
                    NSUserDefaults.standardUserDefaults().setValue(returnRecord!.subscriptionID, forKey: SubscriptionIDs.ChatSubscriptionID)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
                if shouldResumeChainOfSubscriptions == true {
                    self.subscribeForItemAdditionUpdation()
                }
                completionHandler()
            }))
    }
    
    func subscribeForItemAdditionUpdation() {
         let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "OwnerFacebookID != %@", me.facebookID!)
        let subscription = CKSubscription(recordType: "Item",
            predicate: predicate,
            options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        
        let notificationInfo = CKNotificationInfo()
        
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.ItemAdditionOrUpdation
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("ItemAdditionUpdation subscription failed \(err.localizedDescription)")
                } else {
                    logw("ItemAdditionUpdation subscription success")
                }
                self.subscribeForItemDeletion()
            }))
    }
    
    func subscribeForItemDeletion() {
         let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "OwnerFacebookID != %@", me.facebookID!)
        let subscription = CKSubscription(recordType: "Item",
            predicate: predicate,
            options: .FiresOnRecordDeletion)
        
        let notificationInfo = CKNotificationInfo()
        
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.ItemDeletion
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("ItemDeletion subscription failed \(err.localizedDescription)")
                } else {
                    logw("ItemDeletion subscription success")
                }
                self.subscribeForDisablingProfile()
            }))
    }
    
    func subscribeForDisablingProfile() {
         let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let predicate = NSPredicate(format: "creatorUserRecordID != %@", CKRecordID(recordName: me.recordIDName!))
        let subscription = CKSubscription(recordType: RecordTypes.UsersStatus,
            predicate: predicate,
            options: [.FiresOnRecordUpdate, .FiresOnRecordCreation])
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.UserStatusUpdate
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("DisablingProfile subscription failed \(err.localizedDescription)")
                } else {
                    logw("DisablingProfile subscription success")
                }
                self.subscribeForReviews()
            }))
    }
    
    func subscribeForReviews() {
         let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let recordID = CKRecordID(recordName: me.recordIDName!)
        let predicate = NSPredicate(format: "UserBeingReviewed == %@", CKReference(recordID: recordID, action: .None))
        let subscription = CKSubscription(recordType: "Review",
            predicate: predicate,
            options: .FiresOnRecordCreation)
        
        let notificationInfo = CKNotificationInfo()
        
        notificationInfo.shouldSendContentAvailable = true
        
        if #available(iOS 9.0, *) {
            notificationInfo.category = NotificationCategoryMessages.NewReview
        }
        
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("New Review subscription failed \(err.localizedDescription)")
                } else {
                    logw("New Review  subscription success")
                }
            }))
    }
    
    func subscribeForOfferRecall() {
        
        
        //        var reminderDate = dueDate.addDays(1)
        
        //        //Check if reminderDate is Greater than Right now
        //        if(reminderDate.isGreaterThanDate(currentDateTime))
        //        {
        //            //Do Something...
        //        }
        
        
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        //            let predicate = NSPredicate(format: "TRUEPREDICATE")
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        let myExchangePredicate = NSPredicate(format: "RequestedItemOwnerRecordIDName == %@", me.recordIDName!)
        let datePredicate = NSPredicate(format: "modificationDate < %@", me)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[myExchangePredicate,datePredicate])
        
        let subscription = CKSubscription(recordType: "Exchange",
            predicate: compoundPredicate,
            options: .FiresOnRecordCreation)
        
        let notificationInfo = CKNotificationInfo()
        
        notificationInfo.alertBody = NotificationMessages.ExchangeRecall
        notificationInfo.shouldBadge = true
        
        subscription.notificationInfo = notificationInfo
        
        publicDatabase.saveSubscription(subscription,
            completionHandler: ({returnRecord, error in
                if let err = error {
                    logw("subscription failed \(err.localizedDescription)")
                } else {
                    logw("subscription success")
                }
            }))
    }
    
    func deleteAllSubscription(completionBlock: (Void -> Void) = {}) {
         if !NetworkConnection.connectedToNetwork() {
            return
        }
        let database = CKContainer.defaultContainer().publicCloudDatabase
        database.fetchAllSubscriptionsWithCompletionHandler({subscriptions, error in
            for subscriptionObject in subscriptions! {
                let subscription: CKSubscription = subscriptionObject as CKSubscription
                logw("Subscription :\(subscription)")
                
                database.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {subscriptionId, error in
                    logw("Subscription with id \(subscriptionId!) was removed : \(subscription.description)")
                })
            }
        })
    }
    
    func deleteSubscriptionsWithIDs(subscriptionIDs: [String]) {
         let database = CKContainer.defaultContainer().publicCloudDatabase
            for subscriptionID in subscriptionIDs {
                
                database.deleteSubscriptionWithID(subscriptionID, completionHandler: {subscriptionId, error in
                    logw("Subscription with id \(subscriptionId!) was removed.")
                })
            }
    }
    
    //MARK: - s3 methods
    
    func uploadRequestForImageWithKey(key: String,andImage image: UIImage) -> AWSS3TransferManagerUploadRequest {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) ket: \(key)")
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = BuckeyKeys.bucket
        uploadRequest.key = key
        
        let testFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("temp")
        UIImageJPEGRepresentation(image, 0.5)!.writeToURL(testFileURL, atomically: true)
        uploadRequest.body = testFileURL
        
        return uploadRequest
    }
    
    func downloadRequestForImageWithKey(uniqueName: String, downloadingFilePath: String) -> AWSS3TransferManagerDownloadRequest {
        let readRequest1 = AWSS3TransferManagerDownloadRequest()
        readRequest1.bucket = BuckeyKeys.bucket
        readRequest1.key = uniqueName
//        let downloadingFileURL = NSURL(string: NSTemporaryDirectory())!.URLByAppendingPathComponent("temp-download")
        let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath).URLByAppendingPathComponent(randomStringWithLength(10) as String)
        readRequest1.downloadingFileURL = downloadingFileURL
        
        return readRequest1
    }
    
    func filterUrlForDownload(url: NSURL) -> String{
        let urlString = "\(url)"
        if urlString.hasPrefix("file://") {
           return urlString.stringByReplacingOccurrencesOfString("file://", withString: "")
        } else if urlString.hasPrefix("var://"){
           return urlString.stringByReplacingOccurrencesOfString("var://", withString: "")
        }
        return ""
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
}

let modelSingletonGlobal = Model()
let managedConcurrentObjectContext = NSManagedObjectContext.MR_context()
let __appID__ = "779996698766247"
let __appSecret__ = "c119d1732d1997d19ed55e64c30a2da0"

//s3
var transferManager1 = AWSS3TransferManager.defaultS3TransferManager()
private let s3URL = "https://s3.amazonaws.com/peruze/"
func s3Url(uniqueName: String) -> String {
    return "\(s3URL)\(uniqueName)"
}

func createUniqueName() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "EEE_MMM_dd_HH_mm_ss_yyyy"
    let date = NSDate()
    let formattedDate = dateFormatter.stringFromDate(date)

    let me = Person.MR_findFirstByAttribute("me", withValue: true)
    if me.valueForKey("recordIDName") != nil {
        return "\(me.valueForKey("recordIDName")!)\(formattedDate)".stringByReplacingOccurrencesOfString(" ", withString: "")
    } else {
        return "\(me.valueForKey("facebookID")!)\(formattedDate)".stringByReplacingOccurrencesOfString(" ", withString: "")
    }
    
}

