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
    static let ItemAdditionOrUpdation = "A new item has been added"
    static let ItemDeletion = "An item has been deleted"
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
    private var publicDB = CKContainer.defaultContainer().publicCloudDatabase
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
    
    func fetchItemWithRecord(recordID: CKRecordID) -> Void
    {
        self.publicDB.fetchRecordWithID(recordID,
            completionHandler: ({record, error in
                if let err = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        //                        self.notifyUser("Fetch Error", message:
                        //                            err.localizedDescription)
                        logw("Error while fetching Item : \(err)")
                    }
                } else {
                    if record?.recordType == RecordTypes.Item {
                        
                        let localUpload = Item.MR_findFirstOrCreateByAttribute("recordIDName",
                            withValue: record!.recordID.recordName, inContext: managedConcurrentObjectContext)
                        
                        localUpload.setValue(record!.recordID.recordName, forKey: "recordIDName")
                        
                        let ownerRecordIDName = record!.creatorUserRecordID!.recordName
                        
                        if ownerRecordIDName == "__defaultOwner__" {
                            let owner = Person.MR_findFirstByAttribute("me",
                                withValue: true,
                                inContext: managedConcurrentObjectContext)
                            localUpload.setValue(owner, forKey: "owner")
                        } else {
                            let owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                                withValue: ownerRecordIDName,
                                inContext: managedConcurrentObjectContext)
                            localUpload.setValue(owner, forKey: "owner")
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
                        
                        if let imageAsset = record!.objectForKey("Image") as? CKAsset {
                            let imageData = NSData(contentsOfURL: imageAsset.fileURL)
                            localUpload.setValue(imageData, forKey: "image")
                        }
                        
                        if let itemLocation = record!.objectForKey("Location") as? CLLocation {//(latitude: itemLat.doubleValue, longitude: itemLong.doubleValue)
                            
                            if let latitude : Double = Double(itemLocation.coordinate.latitude) {
                                localUpload.setValue(latitude, forKey: "latitude")
                            }
                            
                            if let longitude : Double = Double(itemLocation.coordinate.longitude) {
                                localUpload.setValue(longitude, forKey: "longitude")
                            }
                        }
                        
                        if localUpload.hasRequested != "yes" {
                            localUpload.setValue("no", forKey: "hasRequested")
                        }
                        
                        //save the context
                        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                        NSNotificationCenter.defaultCenter().postNotificationName("reloadPeruseItemMainScreen", object: nil)
                    }
                }
        }))
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
                    if record?.recordType == RecordTypes.Exchange {
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
                        //                    requestingPerson.setValue(set as NSSet, forKey: "exchanges")
                        
                        //save the context
                        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
                        if NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") != nil && NSUserDefaults.standardUserDefaults().valueForKey("isRequestsShowing") as! String == "yes"{
                            NSNotificationCenter.defaultCenter().postNotificationName("getRequestedExchange", object: nil)
                        }
                    }
                }
            }))
    }
    
    func fetchChatWithRecord(recordID: CKRecordID) -> Void
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
                        
                        let sender = Person.MR_findFirstOrCreateByAttribute("me",
                            withValue: true,
                            inContext: managedConcurrentObjectContext)
                        if (record!.creatorUserRecordID?.recordName == "__defaultOwner__") ||
                            (record!.creatorUserRecordID?.recordName == sender?.valueForKey("recordIDName") as! String) {
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
    
    func getMutualFriendsFromLocal(owner: NSManagedObject!, context: NSManagedObjectContext!) -> NSMutableArray {
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
            let mutualFriends: NSMutableArray = []
            for id in myFriendsIDs{
                if otherUserFriendsIDs.containsObject(id) {
                    mutualFriends.addObject(id)
                }
            }
            owner.setValue(mutualFriends.count, forKey: "mutualFriends")
            context.MR_saveToPersistentStoreAndWait()
            return mutualFriends
        }
        return []
    }
}





let modelSingletonGlobal = Model()
let managedConcurrentObjectContext = NSManagedObjectContext.MR_context()

