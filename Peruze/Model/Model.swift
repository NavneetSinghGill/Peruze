//
//  Model.swift
//  Peruse
//
//  Created by Phillip Trent on 7/4/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit
import FBSDKLoginKit
import JSQMessagesViewController
import MagicalRecord

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
}
struct SubscritionTypes {
  static let PeruzeItemUpdates = "PeruzeItemUpdates"
}
struct RecordTypes {
  static let Item = "Item"
  static let Exchange = "Exchange"
  static let Chat = "Chat"
  static let Review = "Review"
  static let User = "Users"
}
class Model: NSObject, CLLocationManagerDelegate {
  var myProfile: Person!
  var locationManager: CLLocationManager!
  private let publicDB = CKContainer.defaultContainer().publicCloudDatabase
  
  class func sharedInstance() -> Model {
    return modelSingletonGlobal
  }
  
  override init() {
    super.init()
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.distanceFilter = kCLDistanceFilterNone
    locationManager.activityType = .Other
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    locationManager.startMonitoringSignificantLocationChanges()
    
  }
  
  private func userPrivacySetting() -> FriendsPrivacy {
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
  private func userDistanceIsEverywhere() -> Bool {
    return userDistanceSettingInMi() == 25
  }
  private func userDistanceSettingInMi() -> Int {
    return NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UsersDistancePreference) as? Int ?? 25
  }
  private func userDistanceSettingInMeters() -> Float {
    return convertToKilometers(userDistanceSettingInMi()) * 1000
  }
  private func convertToKilometers(miles: Int) -> Float {
    return Float(miles) * 1.60934
  }
  
  //MARK: - Profile Setup
  
  func fetchMyMinimumProfileWithCompletion(completion: (Person?, NSError? -> Void)) {
    let fetchMyProfileOp = GetCurrentUserOperation(database: publicDB)
    fetchMyProfileOp.addCondition(CloudContainerCondition(container: CKContainer.defaultContainer()))
    fetchMyProfileOp
    let blockCompletionOp = BlockOperation { () -> Void in
      let fetchedPerson: Person? = Person.findFirstByAttribute("me", withValue: true)
      completion(fetchedPerson, nil)
    }
    blockCompletionOp.addDependency(fetchMyProfileOp)
    OperationQueue.mainQueue().addOperations([fetchMyProfileOp, blockCompletionOp], waitUntilFinished: false)
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
//  MARK: - Profile Setup
//  
//  func setFacebookProfileForLoggedInUser(profile: FBSDKProfile, andImage image: UIImage,  withCompletion completion: (NSError? -> Void)? = nil) {
//    setInfoForLoggedInUser(profile.firstName, lastName: profile.lastName, facebookID: profile.userID, image: image, completion: completion)
//  }
//  func setInfoForLoggedInUser(firstName: String?, lastName: String?, facebookID: String?, image: UIImage, completion:(NSError? -> Void)? = nil) {
//    let imageName = firstName?.stringByReplacingOccurrencesOfString(" ", withString: "_", options: .CaseInsensitiveSearch, range: nil)
//    let (localImageURL, _) = saveImage(image, withName: imageName ?? "temp_file")
//    let imageAsset = CKAsset(fileURL: localImageURL!)
//    
//    //create the fetch and save user operations
//    let startIndicator = StartNetworkIndicator()
//    let fetchUserOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
//    let saveUserOperation = CKModifyRecordsOperation()
//    let removeImageOperation = RemoveFileAtPath(path: localImageURL!.path!)
//    let stopIndicator = StopNetworkIndicator()
//    
//    //make an operation to pass along the record and recordID
//    fetchUserOperation.perRecordCompletionBlock = { (record, recordID, error) -> Void in
//      //check for error
//      if error != nil { completion?(error); return }
//      print("Successfully fetched record with id \(recordID)")
//      //modify the record
//      if firstName != nil { record!.setObject(firstName, forKey: "FirstName") }
//      if lastName != nil { record!.setObject(lastName, forKey: "LastName") }
//      if facebookID != nil { record!.setObject(facebookID, forKey: "FacebookID") }
//      record!.setObject(imageAsset, forKey: "Image")
//      //save the record
//      saveUserOperation.recordsToSave = [record!]
//      self.publicDB.addOperation(saveUserOperation)
//    }
//    
//    saveUserOperation.modifyRecordsCompletionBlock = {(savedRecords, deletedRecordIDs, operationError) -> Void in
//      print("Saved the following records \(savedRecords)")
//      self.myProfile = Person(record: savedRecords!.first!, database: self.publicDB)
//      if operationError != nil {
//        completion?(operationError)
//      } else {
//        completion?(nil)
//      }
//    }
//    
//    //add dependencies
//    fetchUserOperation.addDependency(startIndicator)
//    removeImageOperation.addDependency(saveUserOperation)
//    stopIndicator.addDependency(removeImageOperation)
//    
//    let queue = NSOperationQueue.currentQueue() ?? NSOperationQueue.mainQueue()
//    queue.addOperation(startIndicator)
//    publicDB.addOperation(fetchUserOperation)
//    //save user operation is added inside fetch user operation's completion block
//    queue.addOperation(removeImageOperation)
//    queue.addOperation(stopIndicator)
//  }
//  
//  //MARK: - For Peruse Screen
//  
//  private var usersWithinRangeCursor: CKQueryCursor?
//  private var cursorDistanceSettingInMi: Int?
//  func fetchItemsWithinRangeAndPrivacy() {
//    print(__FUNCTION__)
//    var itemQueryResults = [CKRecord]()
//    
//    
//    let queryCompletionBlock = { (cursor: CKQueryCursor? , error: NSError?) -> Void in
//      self.usersWithinRangeCursor = cursor
//      if error != nil {
//        print(error!.localizedDescription)
//        print(error!.localizedFailureReason)
//        print(error!.localizedRecoverySuggestion)
//        self.postNotificationOnMainThread(NotificationCenterKeys.Error.PeruzeUpdateError, forObject: error)
//        return
//      }
//      self.peruseItems.removeAll(keepCapacity: false)
//      //make asynchronous closure for updating items
//      let updatePeruseItems = AsyncClosuresOperation(queueKind: .Main, asyncClosure: {
//        (controller: AsyncClosureObjectProtocol) -> Void in
//        
//        //for each item, make CKRecord into Item and
//        for item in itemQueryResults {
//          let newItem = Item(record: item, database: self.publicDB)
//          self.fetchMinimumPersonForID(item.creatorUserRecordID!, completion: { (owner, error) -> Void in
//            newItem.owner = owner
//            self.peruseItems.append(newItem)
//            if item == itemQueryResults.last! {
//              controller.finishClosure()
//            }
//          })
//        }
//      })
//      updatePeruseItems.completionBlock = {
//        self.postNotificationOnMainThread(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, forObject: nil)
//      }
//      (NSOperationQueue.currentQueue() ?? NSOperationQueue.mainQueue()).addOperation(updatePeruseItems)
//      
//      
//      //work with results
//    }
//    
//    switch userPrivacySetting() {
//    case .Everyone :
//      let itemsWithinRangeQuery = queryForItemsWithinRange()
//      let itemsOp = CKQueryOperation(query: itemsWithinRangeQuery)
//      itemsOp.desiredKeys = nil //TODO: Change this
//      itemsOp.recordFetchedBlock = { (itemRecord) -> Void in
//        print("item in range record = \(itemRecord)")
//        itemQueryResults.append(itemRecord)
//      }
//      itemsOp.queryCompletionBlock = queryCompletionBlock
//      publicDB.addOperation(itemsOp)
//      break
//    case .Friends :
//      let fetchFriends = FetchFacebookFriends()
//      fetchFriends.completionHandler = { (operation) -> Void in
//        if operation.error != nil {
//          print(operation.error!)
//          return
//        }
//        if let friendsOp = operation as? FetchFacebookFriends {
//          print(friendsOp.facebookIDs)
//          let friendsPredicate = NSPredicate(format: "OwnerFacebookID IN %@", friendsOp.facebookIDs)
//          let rangeAndPrivacyPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([self.queryForItemsWithinRange().predicate, friendsPredicate])
//          let rangeAndPrivacyQuery = CKQuery(recordType: RecordTypes.Item, predicate: rangeAndPrivacyPredicate)
//          let rangeAndPrivacyOp = CKQueryOperation(query: rangeAndPrivacyQuery)
//          rangeAndPrivacyOp.queryCompletionBlock = queryCompletionBlock
//          rangeAndPrivacyOp.recordFetchedBlock = { (itemRecord) -> Void in
//            print("item in range record = \(itemRecord)")
//            itemQueryResults.append(itemRecord)
//          }
//          self.publicDB.addOperation(rangeAndPrivacyOp)
//        }
//      }
//      NSOperationQueue.mainQueue().addOperation(fetchFriends)
//      break
//    case .FriendsOfFriends :
//      break
//    }
//  }
//  
//  
//  private func queryForItemsWithinRange() -> CKQuery {
//    print(__FUNCTION__)
//    //check authorization status
//    let authorized = CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways
//    
//    //create predicates
//    let notMyItemsPredicate = NSPredicate(format: "creatorUserRecordID != %@", myProfile!.recordID)
//    let everywhereLocation = NSPredicate(value: true)
//    let specificLocation = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
//      "Location",
//      locationManager.location ?? CLLocation(),
//      userDistanceSettingInMeters())
//    
//    //choose and concatenate predicates
//    let locationPredicate = userDistanceIsEverywhere() || !authorized ? everywhereLocation : specificLocation
//    let othersInRange = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [locationPredicate, notMyItemsPredicate])
//    
//    //fetch users within range of self.location
//    let usersWithinRangeQuery = CKQuery(recordType: RecordTypes.Item, predicate: othersInRange)
//    return usersWithinRangeQuery
//  }
//  
//  
//  private func createSubscriptionForItems() {
//    print("Create Subscription for Items")
//    let predicate = NSPredicate(format: "creatorUserRecordID != %@", myProfile!.recordID)
//    let subscription = CKSubscription(recordType: RecordTypes.Item,
//      predicate: predicate,
//      subscriptionID: SubscritionTypes.PeruzeItemUpdates,
//      options: [.FiresOnRecordUpdate, .FiresOnRecordCreation, .FiresOnRecordDeletion])
//    publicDB.saveSubscription(subscription, completionHandler: { (savedSubscription, error) -> Void in
//      if error != nil {
//        //handle error
//        print(error!.localizedDescription)
//        return
//      } else {
//        print("- - - - - Subscription Saved - - - - -")
//        print(savedSubscription)
//      }
//    })
//  }
//  private func fetchOwnerForItem(inout item: Item, withRecordID recordID: CKRecordID?) {
//    if recordID == nil {
//      item.owner = Person()
//      self.peruseItems.append(item)
//      self.postNotificationOnMainThread(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, forObject: item)
//    } else {
//      publicDB.fetchRecordWithID(recordID!, completionHandler: { (ownerRecord, error) -> Void in
//        if error != nil {
//          self.postNotificationOnMainThread(NotificationCenterKeys.Error.PeruzeUpdateError, forObject: error)
//        } else {
//          item.owner = Person(record: ownerRecord!, database: self.publicDB)
//          self.peruseItems.append(item)
//          self.postNotificationOnMainThread(NotificationCenterKeys.PeruzeItemsDidFinishUpdate, forObject: item)
//        }
//      })
//    }
//    //TODO: Use NSOperations
//  }
//  func fetchUserProfileForItem(item: Item) {
//    
//  }
//  //MARK: - For Exchanges Screen
//  func uploadRequest(request: Exchange) {
//    let newRequest = CKRecord(recordType: RecordTypes.Exchange)
//    
//    let offeredReference = CKReference(recordID: request.itemOffered.id, action: CKReferenceAction.DeleteSelf)
//    let requestedReference = CKReference(recordID: request.itemRequested.id, action: CKReferenceAction.DeleteSelf)
//    newRequest.setObject(request.status.rawValue, forKey: "ExchangeStatus")
//    newRequest.setObject(offeredReference, forKey: "OfferedItem")
//    newRequest.setObject(requestedReference, forKey: "RequestedItem")
//    let saveNewRequestOp = CKModifyRecordsOperation(recordsToSave: [newRequest], recordIDsToDelete: nil)
//    publicDB.addOperation(saveNewRequestOp)
//  }
//  //MARK: - For Upload Screen
//  func uploadItemWithImage(image: UIImage!, title: String, andDetails details: String) {
//    //change the image into a url
//    let pngData = UIImagePNGRepresentation(image)
//    let imageName = title.stringByReplacingOccurrencesOfString(" ", withString: "_", options: .CaseInsensitiveSearch, range: nil)
//    let path = documentsPathForFileName(imageName + ".png")
//    if !pngData!.writeToFile(path, atomically: true) {
//      //there was an error writing the data
//      print("There was an error writing the png writing to the file.")
//    }
//    assert(myProfile != nil, "myProfile can not be nil when trying to upload an item")
//    let newItem = CKRecord(recordType: RecordTypes.Item)
//    let imageAsset = CKAsset(fileURL: NSURL(fileURLWithPath: path))
//    newItem.setObject(title, forKey: "Title")
//    newItem.setObject(details, forKey: "Description")
//    newItem.setObject(imageAsset, forKey: "Image")
//    newItem.setObject(myProfile!.id, forKey: "OwnerFacebookID")
//    if locationManager.location != nil {
//      newItem.setObject(locationManager.location, forKey: "Location")
//    }
//    
//    publicDB.saveRecord(newItem, completionHandler: { (savedRecord, error) -> Void in
//      if error == nil {
//        //successfully saved
//        print("---- record saved ----")
//        print(savedRecord)
//        self.postNotificationOnMainThread(NotificationCenterKeys.UploadItemDidFinishSuccessfully, forObject: savedRecord)
//        var removeError: NSError? {
//          didSet {
//            print(removeError?.localizedDescription)
//            //handle error
//          }
//        }
//        do {
//          try NSFileManager.defaultManager().removeItemAtPath(path)
//        } catch let error as NSError {
//          removeError = error
//        } catch {
//          fatalError()
//        }
//      } else {
//        print(error!.localizedDescription)
//        //error handling
//      }
//    })
//  }
//  
//  //MARK: - For Chat Screen
//  func uploadMessage(message: JSQMessage, forChat chat: Chat) {
//    
//  }
//  
//  func startChatBetweenPursuing(exchange: Exchange) {
//    
//  }
//  
//  func cancelExchange(exchange: Exchange) {
//    
//  }
//  
//  func completeExchange(exchange: Exchange) {
//    
//  }
//  
//  //MARK: - For Requests Screen
//  func fetchExchangeRequests(completion: ([Exchange]?, NSError?) -> Void) {
//    ///All errors returned from each request to pass back to the user
//    var aggregatedErrors = [NSError]()
//    
//    //Make sure that there are uploads to reference
//    if let profileUploads = myProfile?.uploads {
//      //create the predicate
//      let possibleRequestedItems = profileUploads.map { CKReference(recordID: $0.id, action: .DeleteSelf) }
//      let requestedItemPredicate = NSPredicate(format: "RequestedItem IN %@", possibleRequestedItems)
//      let pendingRequestPredicate = NSPredicate(format: "ExchangeStatus == %i", ExchangeStatus.Pending.rawValue)
//      let requestPredicate = NSCompoundPredicate.andPredicateWithSubpredicates([pendingRequestPredicate, requestedItemPredicate])
//      
//      //clear requests
//      //TODO: Make this able to insert/delete specific indexPaths
//      self.requests = []
//      
//      //create the operation
//      let requestQueryOp = CKQueryOperation(query: CKQuery(recordType: RecordTypes.Exchange, predicate: requestPredicate))
//      //handle per-record completion
//      requestQueryOp.recordFetchedBlock = { (record) -> Void in
//        self.requests.append(Exchange(record: record))
//      }
//      //handle full completion
//      requestQueryOp.queryCompletionBlock = { (_, error) -> Void in
//        if error != nil {
//          print("Fetch Exchange Requests Has An Error:")
//          print(error)
//          aggregatedErrors.append(error!)
//        }
//        self.fetchItemsForExchangeObjectsOperation(self.requests) { (completeExchanges:[Exchange]?, error: NSError?) -> Void in
//          self.requests = completeExchanges!
//          if error != nil { aggregatedErrors.append(error!) }
//          completion(completeExchanges, aggregatedErrors.last)
//        }
//      }
//      publicDB.addOperation(requestQueryOp)
//    }
//  }
//  
//  private func fetchItemsForExchangeObjectsOperation(exchanges: [Exchange], completion: ([Exchange]?, NSError?) -> Void) {
//    //check for exchanges
//    if exchanges.count == 0 {
//      completion([], nil)
//    }
//
//    
//    
////    var aggregatedErrors = [NSError]()
////    var itemOfferedRecordIDs = exchanges.map({ $0.itemOffered.id })
////    let finishOperation = NSBlockOperation {
////      completion([], aggregatedErrors.last)
////    }
////    let fetchItemsOffered = CKFetchRecordsOperation(recordIDs: itemOfferedRecordIDs)
////    fetchItemsOffered.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
////      if error != nil { aggregatedErrors.append(error!) }
////      
////      
////    }
//
//    
//    
//    
//    
//    
//    var aggregatedErrors = [NSError]()
//    var returnExchanges = exchanges
//    let collectedRecordIDs = exchanges.map({ $0.itemOffered.id! })
//    let fetchRecords = CKFetchRecordsOperation(recordIDs: collectedRecordIDs)
//    fetchRecords.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
//      if error != nil {
//        print("Fetch Items For Exchange Requests Has An Error:")
//        print(error)
//        aggregatedErrors.append(error!)
//      }
//      //handle exchanges
//      for i in 0..<returnExchanges.count {
//        //find item requested
//        if let uploads = self.myProfile?.uploads {
//          for upload in uploads {
//            if upload.id == returnExchanges[i].itemRequested.id {
//              returnExchanges[i].itemRequested = upload
//            }
//          }
//        }
//        //find item offered
//        if let matchingOfferedItem = recordsByID![returnExchanges[i].itemOffered.id] {
//          returnExchanges[i].itemOffered = Item(record: matchingOfferedItem, database: self.publicDB)
//          self.fetchMinimumPersonForID(matchingOfferedItem.creatorUserRecordID!, completion: { (owner, error) -> Void in
//            if error != nil {
//              print("Fetch Minimum Person For ID (Exchange Requests) Has An Error:")
//              print(error)
//              aggregatedErrors.append(error!)
//            }
//            assert(owner != nil, "owner returned from fetchMinimumPersonForID was nil")
//            returnExchanges[i].itemOffered.owner = owner
//            if i == returnExchanges.count - 1 {
//              completion(returnExchanges, aggregatedErrors.last)
//            }
//          })
//        }
//      }
//    }
//    publicDB.addOperation(fetchRecords)
//  }
//  
//  /**
//  Accepts an exchange request from the Requests section
//  - parameter exchange: The exchange that is being accepted
//  - parameter completion: A completion block that returns the updated set of requests and the error from interacting with the database
//  */
//  func acceptExchangeRequest(exchange: Exchange, completion: (([Exchange]?, NSError?) -> Void)? = nil) {
//    ///Errors to return to the user
//    var aggregatedErrors = [NSError]()
//    
//    ///The exchange record to update the database with
//    let modifiedExchange = CKRecord(recordType: RecordTypes.Exchange, recordID: exchange.recordID)
//    modifiedExchange.setObject(ExchangeStatus.Accepted.rawValue, forKey: "ExchangeStatus")
//    
//    ///The operation for saving the modified exchange to the server
//    let modifyExchangeOp = CKModifyRecordsOperation(recordsToSave: [modifiedExchange], recordIDsToDelete: nil)
//    modifyExchangeOp.savePolicy = .ChangedKeys //forces update without fetch
//    modifyExchangeOp.modifyRecordsCompletionBlock = { (recordsSaved, recordsDeleted, error) -> Void in
//      if error != nil { aggregatedErrors.append(error!) }
//    }
//    
//    ///Operation wrapper for fetching the exchange requests
//    let fetchRequests = NSBlockOperation { () -> Void in
//      self.fetchExchangeRequests({ (exchanges, error) -> Void in
//        if error != nil { aggregatedErrors.append(error!) }
//        completion?(exchanges, aggregatedErrors.last)
//      })
//    }
//    
//    //the request to fetch the new exchanges has to wait on the saving of the modified exchange
//    fetchRequests.addDependency(modifyExchangeOp)
//    
//    //add operations to their queues
//    publicDB.addOperation(modifyExchangeOp)
//    NSOperationQueue.mainQueue().addOperation(fetchRequests)
//  }
//  
//  /**
//  Denies an exchange request from the Requests section
//  - parameter exchange: The exchange that is being denied
//  - parameter completion: A completion block that returns the updated set of requests and the error from interacting with the database
//  */
//  func denyExchangeRequest(exchange: Exchange, completion: (([Exchange]?, NSError?) -> Void)? = nil) {
//    ///Errors to return to the user
//    var aggregatedErrors = [NSError]()
//    
//    ///The exchange record to update the database with
//    let modifiedExchange = CKRecord(recordType: RecordTypes.Exchange, recordID: exchange.recordID)
//    modifiedExchange.setObject(ExchangeStatus.Denied.rawValue, forKey: "ExchangeStatus")
//    
//    ///The operation for saving the modified exchange to the server
//    let modifyExchangeOp = CKModifyRecordsOperation(recordsToSave: [modifiedExchange], recordIDsToDelete: nil)
//    modifyExchangeOp.savePolicy = .ChangedKeys //forces update without fetch
//    modifyExchangeOp.modifyRecordsCompletionBlock = { (recordsSaved, recordsDeleted, error) -> Void in
//      if error != nil { aggregatedErrors.append(error!) }
//    }
//    
//    ///Operation wrapper for fetching the exchange requests
//    let fetchRequests = NSBlockOperation { () -> Void in
//      self.fetchExchangeRequests({ (exchanges, error) -> Void in
//        if error != nil { aggregatedErrors.append(error!) }
//        completion?(exchanges, aggregatedErrors.last)
//      })
//    }
//    
//    //the request to fetch the new exchanges has to wait on the saving of the modified exchange
//    fetchRequests.addDependency(modifyExchangeOp)
//    
//    //add operations to their queues
//    publicDB.addOperation(modifyExchangeOp)
//    NSOperationQueue.mainQueue().addOperation(fetchRequests)
//  }
//  
//  //MARK: - For Profile Screen
//  
//  func completePerson(person: Person, completion: ((Person?, NSError?) -> Void)){
//    let returnPerson: Person = person
//    var desiredKeys = [String]()
//    //check for recordID and facebookID
//    assert(person.recordID != nil,
//      "Trying to complete a person without a recordID")
//    assert(person.id != nil && !person.id.isEmpty,
//      "Trying to complete a person without a facebook ID")
//    
//    //mutualFriends
//    if person.mutualFriends == nil {
//      //TODO: get mutual friends
//      returnPerson.mutualFriends = 0
//    }
//    //image
//    if person.image == nil { desiredKeys.append("Image") }
//    //firstName
//    if person.firstName == nil || person.firstName.isEmpty {
//      desiredKeys.append("FirstName")
//    }
//    //lastName
//    if person.lastName == nil || person.lastName.isEmpty{
//      desiredKeys.append("LastName")
//    }
//    
//    //uploads (always retrieve)
//    //favorites (always retrieve)
//    //reviews (always retrieve)
//    //completedExchanges (always retrieve)
//    let fetch = FetchFullProfileForUserRecordID(recordID: person.recordID, desiredKeys: desiredKeys)
//    fetch.completionHandler = { (completedOperation) -> Void in
//      if completedOperation.error != nil {
//        completion(nil, completedOperation.error)
//      }
//      if let op = completedOperation as? FetchFullProfileForUserRecordID {
//        completion(op.person, op.error)
//        if person.recordID == (self.myProfile?.recordID ?? CKRecordID(recordName: "false")) {
//          self.myProfile = op.person
//          self.postNotificationOnMainThread(NotificationCenterKeys.UploadsDidFinishUpdate, forObject: nil)
//          self.postNotificationOnMainThread(NotificationCenterKeys.FavoritesDidFinishUpdate, forObject: nil)
//        }
//      }
//    }
//    NSOperationQueue().addOperation(fetch)
//  }
//  
//  func fetchMinimumPersonForID(recordID: CKRecordID, completion: (Person?, NSError?) -> Void) {
//    let fetchOperation = CKFetchRecordsOperation(recordIDs:[recordID])
//    fetchOperation.desiredKeys = ["FirstName", "LastName", "Image", "FacebookID"]
//    fetchOperation.perRecordCompletionBlock = { (record, _, error) -> Void in
//      print("Person fetched with record: \(record) and error: \(error)")
//      if error != nil {
//        print(error!.localizedDescription)
//        completion(Person(), error)
//      } else {
//        let result = Person(record: record!, database: self.publicDB)
//        completion(result, error)
//      }
//    }
//    publicDB.addOperation(fetchOperation)
//  }
//  
//  func fetchMyMinimumProfileWithCompletion(completion: (Person?, NSError?) -> Void) {
//    print(__FUNCTION__)
//    if myProfile != nil {
//      completion(myProfile, nil)
//    } else {
//      let fetchMyRecordOp = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
//      fetchMyRecordOp.perRecordCompletionBlock = { (record, recordID, error) -> Void in
//        if error != nil { completion(nil, error); return }
//        let personResult = Person(record: record!)
//        self.myProfile = personResult
//        completion(self.myProfile, nil)
//      }
//      publicDB.addOperation(fetchMyRecordOp)
//    }
//  }
//  
//  func fetchMyProfileWithCompletion(completion: (Person?, NSError?) -> Void) {
//    print("fetch my profile with completion")
//    if myProfile != nil {
//      self.completePerson(myProfile!, completion: { (completedPerson, completionError) -> Void in
//        self.myProfile = completedPerson
//        completion(completedPerson, completionError)
//      })
//    } else {
//      let fetchMyRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
//      fetchMyRecordOperation.perRecordCompletionBlock = { (record, recordID, error) -> Void in
//        if error != nil { completion(nil, error); return }
//        self.myProfile = Person(record: record!, database: self.publicDB)
//        print("fetch my record operation")
//        
//        self.completePerson(self.myProfile!, completion: { (completedProfile, completionError) -> Void in
//          if completionError != nil {
//            completion (nil, completionError)
//            return
//          }
//          self.myProfile = completedProfile
//          completion(completedProfile, completionError)
//        })
//      }
//      publicDB.addOperation(fetchMyRecordOperation)
//    }
//  }
//  //MARK: - For Write Review Screen
//  func uploadReview(review: Review, forUser user: Person) {
//    
//  }
//  //MARK: - Location Delegate
//  func updateUserLocation(location: CLLocation) {
//    if myProfile == nil { return }
//    let myNewLocationRecord = CKRecord(recordType: RecordTypes.User, recordID: (CKRecordID(recordName: myProfile!.recordIDName!)))
//    myNewLocationRecord.setObject(location, forKey: "Location")
//    let modifyOperation = CKModifyRecordsOperation(recordsToSave: [myNewLocationRecord], recordIDsToDelete: nil)
//    
//    modifyOperation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) -> Void in
//      print("- - - - - - Location Record Saved - - - - - - - - -")
//      print(savedRecords)
//      print("- - - - - Location Record Error - - - - - - -")
//      print(error ?? "No error")
//    }
//    
//    modifyOperation.savePolicy = CKRecordSavePolicy.ChangedKeys
//    publicDB.addOperation(modifyOperation)
//  }
//  
//  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//    switch status {
//    case .AuthorizedAlways:
//      locationManager.startUpdatingLocation()
//      break
//    case .AuthorizedWhenInUse, .Denied, .Restricted, .NotDetermined:
//      //TODO: Handle this
//      break
//    }
//  }
//  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
//    print("location manager did fail with error: \(error)")
//  }
//  var currentLocation: CLLocation!
//  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//    currentLocation = currentLocation ?? CLLocationManager().location
//    let newLocation = locations.last! as CLLocation
//    let locationAge = -newLocation.timestamp.timeIntervalSinceNow
//    
//    if locationAge > 5.0 { return }
//    if newLocation.horizontalAccuracy < 0 { return }
//    
//    let distance = currentLocation.distanceFromLocation(newLocation)
//    currentLocation = newLocation
//    
//    if distance > 20 {
//      updateUserLocation(locations.last! as CLLocation)
//    }
//  }
//  
//  //MARK: - Utility and Convenience
//  private func postNotificationOnMainThread(notification: String, forObject object: AnyObject?) {
//    dispatch_async(dispatch_get_main_queue()) { () -> Void in
//      NSNotificationCenter.defaultCenter().postNotificationName(notification, object: object)
//    }
//  }
//  
//  private func documentsPathForFileName(name: String) -> String {
//    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
//    let documentsPath = paths.first! as String
//    return documentsPath.stringByAppendingPathComponent(name)
//  }
//  
//  private func saveImage(image: UIImage, withName name: String) -> (imageURL: NSURL?, error: NSError?) {
//    //Save the image to the user's device
//    var error: NSError?
//    let path = documentsPathForFileName(name + ".png")
//    let pngData = UIImagePNGRepresentation(image)
//    if !pngData!.writeToFile(path, atomically: true) {
//      error = NSError(domain: WriteFileErrorDomain,
//        code: 0,
//        userInfo: [
//          NSLocalizedDescriptionKey: "Error Writing File",
//          NSLocalizedFailureReasonErrorKey: "There was a problem writing an image to your phone's storage. ",
//          NSLocalizedRecoverySuggestionErrorKey: "Close and reopen the application. "
//        ]
//      )
//    }
//    return (NSURL(fileURLWithPath: path), error)
//  }
}
let modelSingletonGlobal = Model()
let managedMainObjectContext = NSManagedObjectContext.MR_defaultContext()
let managedConcurrentObjectContext = NSManagedObjectContext.MR_context()

