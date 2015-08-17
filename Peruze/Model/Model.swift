//
//  Model.swift
//  Peruse
//
//  Created by Phillip Trent on 7/4/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import CloudKit

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
  static let Review = "Review"
  static let User = "Users"
  static let Message = "Message"
}
class Model: NSObject, CLLocationManagerDelegate {
  private let publicDB = CKContainer.defaultContainer().publicCloudDatabase
  private let locationAccuracy: CLLocationAccuracy = 200 //meters
  class func sharedInstance() -> Model {
    return modelSingletonGlobal
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
  
  func getPeruzeItems(presentationContext: UIViewController, completion: (Void -> Void) = {}) {
    let operationQueue = OperationQueue()
    operationQueue.qualityOfService = .UserInitiated
    
    let getLocationOp = LocationOperation(accuracy: locationAccuracy, manager: nil) { (location) -> Void in
      let getItems = GetPeruzeItemOperation(
        presentationContext: presentationContext,
        location: location,
        context: managedConcurrentObjectContext,
        database: self.publicDB
      )
      getItems.completionBlock = completion
      operationQueue.addOperation(getItems)
    }
    let condition = LocationCondition(usage: .WhenInUse, manager: nil)
    
    OperationConditionEvaluator.evaluate([condition], operation: getLocationOp) {
      (errors: [ErrorType]) -> Void in
      if errors.first != nil {
        println("There was an error getting the user's location. Will use Everywhere location preference.")
        let getItems = GetPeruzeItemOperation(
          presentationContext: presentationContext,
          location: CLLocation(),
          context: managedConcurrentObjectContext,
          database: self.publicDB
        )
        getItems.completionBlock = completion
        operationQueue.addOperation(getItems)
      }
    }
    
    operationQueue.addOperation(getLocationOp)
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
}
let modelSingletonGlobal = Model()
let managedConcurrentObjectContext = NSManagedObjectContext.MR_context()

