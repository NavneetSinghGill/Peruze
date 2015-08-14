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

