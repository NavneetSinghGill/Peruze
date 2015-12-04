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
  struct Error {
    static let PeruzeUpdateError = "PeruseUpdateError"
    static let UploadItemError = "UploadItemError"
  }
    
    static let UpdateItemsOnFilterChange = "UpdateItemsOnFilterChange"
}



struct NotificationMessages {
    static let NewOfferMessage = "A new offer made for you"
    static let NewChatMessage = "A new message for you"
    static let ExchangeRecall = "Did you complete your exchange"
}


struct SubscritionTypes {
  static let PeruzeItemUpdates = "PeruzeItemUpdates"
}
struct RecordTypes {
  static let Item = "Item"
  static let Exchange = "Exchange"
  static let Review = "Review"
  static let User = "Users"
  static let Message = "Message"
    static let Friends = "Friends"
}
class Model: NSObject, CLLocationManagerDelegate {
    
    var friendsRecords : NSMutableArray = []
    private let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    private let locationAccuracy: CLLocationAccuracy = 200 //meters
    class func sharedInstance() -> Model {
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
    
    
    
    
    
    
    func fetchExchangeWithRecord(recordID: CKRecordID) -> Void
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
                    let requestingPerson = Person.MR_findFirstByAttribute("me", withValue: true)
                    
                    let localExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
                        withValue: record!.recordID.recordName,
                        inContext: managedConcurrentObjectContext)
                    
                    //set creator
                    if record!.creatorUserRecordID!.recordName == "__defaultOwner__" {
                        let creator = Person.MR_findFirstOrCreateByAttribute("me",
                            withValue: true,
                            inContext: managedConcurrentObjectContext)
                        localExchange.setValue(creator, forKey: "creator")
                    } else {
                        let creator = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.creatorUserRecordID?.recordName,
                            inContext: managedConcurrentObjectContext)
                        localExchange.setValue(creator, forKey: "creator")
                    }
                    
                    //set exchange status
                    if let newExchangeStatus = record!.objectForKey("ExchangeStatus") as? Int {
                        localExchange.setValue(NSNumber(integer: newExchangeStatus), forKey: "status")
                    }
                    
                    //set date
                    if let newDate = record!.objectForKey("DateExchanged") as? NSDate {
                        let date = localExchange.valueForKey("date") as? NSDate
                        localExchange.setValue((date ?? newDate), forKey: "date")
                    }
                    
                    //set item offered
                    if let itemOfferedReference = record!.objectForKey("OfferedItem") as? CKReference {
                        let itemOffered = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: itemOfferedReference.recordID.recordName,
                            inContext: managedConcurrentObjectContext)
                        itemOffered.setValue("yes", forKey: "hasRequested")
                        localExchange.setValue(itemOffered, forKey: "itemOffered")
                    }
                    
                    //set item requested
                    if let itemRequestedReference = record!.objectForKey("RequestedItem") as? CKReference {
                        let itemRequested = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: itemRequestedReference.recordID.recordName,
                            inContext: managedConcurrentObjectContext)
                        itemRequested.setValue("no", forKey: "hasRequested")
                        localExchange.setValue(itemRequested, forKey: "itemRequested")
                        
                    }
                    
                    
                    
                    //add this exchange to the requesting user's exchanges
                    let currentExchanges = requestingPerson.valueForKey("exchanges") as! NSSet
                    
                    let set = currentExchanges.setByAddingObject(localExchange)
                    requestingPerson.setValue(set, forKey: "exchanges")
                    
                    //save the context
                    managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                    if NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") as! String == "yes"{
                        NSNotificationCenter.defaultCenter().postNotificationName("getRequestedExchange", object: nil)
                    }
                }
            }))
    }
    
    func fetchChatWithRecord(recordID: CKRecordID) -> Void
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
                    let localMessage = Message.MR_findFirstOrCreateByAttribute("recordIDName",
                        withValue: record!.recordID.recordName, inContext: managedConcurrentObjectContext)
                    
                    if let messageText = record!.objectForKey("Text") as? String {
                        localMessage.setValue(messageText, forKey: "text")
                    }
                    
                    if let messageImage = record!.objectForKey("Image") as? CKAsset {
                        localMessage.setValue(NSData(contentsOfURL: messageImage.fileURL), forKey: "image")
                    }
                    
                    localMessage.setValue(record!.objectForKey("Date") as? NSDate, forKey: "date")
                    
                    if let exchange = record!.objectForKey("Exchange") as? CKReference {
                        let messageExchange = Exchange.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: exchange.recordID.recordName,
                            inContext: managedConcurrentObjectContext)
                        localMessage.setValue(messageExchange, forKey: "exchange")
                    }
                    
                    if record!.creatorUserRecordID?.recordName == "__defaultOwner__" {
                        let sender = Person.MR_findFirstOrCreateByAttribute("me",
                            withValue: true,
                            inContext: managedConcurrentObjectContext)
                        localMessage.setValue(sender, forKey: "sender")
                    } else {
                        let sender = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.creatorUserRecordID?.recordName,
                            inContext:managedConcurrentObjectContext)
                        localMessage.setValue(sender, forKey: "sender")
                    }
                    
                    //save the context
                    managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                    NSNotificationCenter.defaultCenter().postNotificationName("getChat", object: nil)
                }
            }))
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
            print(record)
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
}





let modelSingletonGlobal = Model()
let managedConcurrentObjectContext = NSManagedObjectContext.MR_context()

