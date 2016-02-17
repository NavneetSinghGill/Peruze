//
//  GetPersonOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/19/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import CloudKit
import SwiftLog

private let logging = true
class GetPersonOperation: Operation {
  let personID: CKRecordID
  let database: CKDatabase
  let context: NSManagedObjectContext
  /**
  - parameter recordID: A valid recordIDName that corresponds to the person
  whom you wish to fetch
  - parameter database: The database to place the fetch request on
  - parameter context: The `NSManagedObjectContext` that will be used as the
  basis for importing data. The operation will internally
  construct a new `NSManagedObjectContext` that points
  to the same `NSPersistentStoreCoordinator` as the
  passed-in context.
  */
  init(recordID: CKRecordID, database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.personID = recordID
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    //figure out what keys need to be fetched
    let person = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: personID.recordName, inContext: context)
    var desiredKeys: [String] = []
    
    if (person.valueForKey("firstName") as? String) == nil {
      desiredKeys.append("FirstName")
    }
    
    if (person.valueForKey("lastName") as? String) == nil {
      desiredKeys.append("LastName")
    }
    
//    if (person.valueForKey("image") as? NSData) == nil {
//      desiredKeys.append("Image")
//    }
    
    
    if (person.valueForKey("facebookID") as? String) == nil {
      desiredKeys.append("FacebookID")
    }
    
    desiredKeys.append("FavoriteItems")
    desiredKeys.append("ImageUrl")
    
    //if the person is complete, finish and return
    if desiredKeys.count == 0 {
      finish()
      return
    }
    
    //create operation for fetching relevant records
    let getPersonOperation = CKFetchRecordsOperation(recordIDs: [personID])
    getPersonOperation.desiredKeys = desiredKeys
    getPersonOperation.fetchRecordsCompletionBlock = { (recordsByID, opError) -> Void in
      guard let recordsByID = recordsByID else {
        self.finishWithError(opError)
        return
      }
      //add person to the database
      let keysArray = recordsByID.keys
      for key in keysArray {
        
        if let recordID = key as? CKRecordID {
          
          //fetch each person with the returned ID
          var localPerson = Person.MR_findFirstOrCreateByAttribute("recordIDName", withValue: recordID.recordName, inContext: self.context)
          if localPerson == nil {
            localPerson = Person.MR_findFirstOrCreateByAttribute("me", withValue: true, inContext: self.context)
          }
          
          //set the returned properties
          localPerson.setValue(recordID.recordName, forKey: "recordIDName")
          
          
          if (localPerson.valueForKey("firstName") as? String) == nil {
            let firstName = recordsByID[recordID]?.objectForKey("FirstName") as? String
            localPerson.setValue(firstName, forKey: "firstName")
          }
          if (localPerson.valueForKey("lastName") as? String) == nil {
            let lastName = recordsByID[recordID]?.objectForKey("LastName") as? String
            localPerson.setValue(lastName, forKey: "lastName")
          }
          if (localPerson.valueForKey("facebookID") as? String) == nil {
            let facebookID = recordsByID[recordID]?.objectForKey("FacebookID") as? String
            localPerson.setValue(facebookID, forKey: "facebookID")
            
            if localPerson.valueForKey("facebookID") != nil {
//                let predicate = NSPredicate(format: "FacebookID == %@", localPerson.valueForKey("facebookID") as! String)
//                let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
//                self.database.performQuery(query, inZoneWithID: nil, completionHandler: {
//                    (friends, error) -> Void in
//                    logw("GetPersonOperation Friends block")
//                    for friend in friends! {
//                        let localFriendRecord = Friend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friend.recordID.recordName, inContext: self.context)
//                        if let facebookID = friend.objectForKey("FacebookID") {
//                            localFriendRecord.setValue(facebookID, forKey: "facebookID")
//                        }
//                        if let friendsFacebookID = friend.objectForKey("FriendsFacebookIDs") {
//                            localFriendRecord.setValue(friendsFacebookID, forKey: "friendsFacebookIDs")
//                        }
//                        let mutualFriends = Model.sharedInstance().getMutualFriendsFromLocal(localPerson, context: self.context)
//                        localPerson.setValue(mutualFriends.count, forKey: "mutualFriends")
//                    }
//                    self.context.MR_saveToPersistentStoreAndWait()
//                })
                
                
                
                
                
                //old implementation=====
                
//                Model.sharedInstance().getMutualFriendsFromFb(localPerson, context_: self.context, completionBlock: {
//                    self.context.MR_saveToPersistentStoreAndWait()
//                    //self.finish()
//                })
                //=======================
                
                
                Model.sharedInstance().getTaggbleFriendsFromCloudAndMatch(localPerson, completionBlock: { taggableFriendsCount in
                    localPerson.setValue(taggableFriendsCount, forKey: "mutualFriends")
                    self.context.MR_saveToPersistentStoreAndWait()
                    self.finish()
                })
                
                
            }
          }
          //check for image property and set the data
//          if let imageAsset = recordsByID[recordID]?.objectForKey("Image") as? CKAsset {
//            let image = NSData(contentsOfURL: imageAsset.fileURL)
//            localPerson.setValue(image, forKey: "image")
//          }
            
            if let imageUrlSuffix = recordsByID[recordID]?.objectForKey("ImageUrl") as? String {
                localPerson.setValue(imageUrlSuffix, forKey: "imageUrl")
            }
//            if let imageUrlSuffix = recordsByID[recordID]?.objectForKey("ImageUrl") as? String {
//                //download image
//                let downloadingFilePath = NSTemporaryDirectory()
//                let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrlSuffix, downloadingFilePath: downloadingFilePath)
//                let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//                let task = transferManager.download(downloadRequest)
//                task.continueWithBlock({ (task) -> AnyObject? in
//                    if task.error != nil {
//                        logw("GetItemOperation image download failed with error: \(task.error!)")
//                    } else {
//                        dispatch_async(dispatch_get_main_queue()) {
//                            let fileUrl = task.result!.valueForKey("body")!
//                            let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                            localPerson.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                            self.context.MR_saveToPersistentStoreAndWait()
//                        }
//                    }
//                    return nil
//                })
//            }
            
          self.context.MR_saveToPersistentStoreAndWait()
        }
        
      }
      //because the operations inside of the block wait, we can call finish outside of the block
      self.finish()
    }
    
    //add that operation to the operationQueue of self.database
    getPersonOperation.qualityOfService = qualityOfService
    self.database.addOperation(getPersonOperation)
  }
}


class GetAllPersonsWithMissingData: Operation {
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    if logging { logw("GetAllPersonsWithMissingData " + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    self.database = database
    self.context = context
    super.init()
  }
  override func execute() {
    if logging { logw("\n\n\(NSDate()) GetAllPersonsWithMissingData exection start" + __FUNCTION__ + " of " + __FILE__ + " called.  ") }
    
    //figure out what keys need to be fetched
    let missingPersonsPredicate = NSPredicate(value: true)//(format: "recordIDName != nil AND image == nil")
    
    let allMissingPersons = Person.MR_findAllWithPredicate(missingPersonsPredicate, inContext: context) as! [NSManagedObject]
    let allMissingPersonsRecordNameID = allMissingPersons.map { $0.valueForKey("recordIDName") as? String }
    let desiredKeys = ["FirstName", "LastName", "FacebookID", "ImageUrl"]
    var missingPersonsRecordIDs = [CKRecordID]()
    for recordIDName in allMissingPersonsRecordNameID {
      if recordIDName != nil {
        missingPersonsRecordIDs.append(CKRecordID(recordName: recordIDName!))
      }
    }
    
    if missingPersonsRecordIDs.count == 0 {
      self.finish()
      return
    }
    
    //create operation for fetching relevant records
    let getPersonOperation = CKFetchRecordsOperation(recordIDs: missingPersonsRecordIDs)
    getPersonOperation.desiredKeys = desiredKeys
    getPersonOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
        logw("\n\n\(NSDate()) GetAllPersonsWithMissingData Per record completion======")
      if let error = error {
        logw("Get All Persons With Missing Data Finished With Error: \(error)")
        self.finishWithError(error)
        return
      }
        
      for recordID in recordsByID!.keys {
        //add person to the database
        
        //fetch each person with the returned ID
        let recordID = recordID 
        var localPerson: Person!
        if recordID.recordName == "__defaultOwner__" {
          localPerson = Person.MR_findFirstOrCreateByAttribute("me",
            withValue: true,
            inContext: self.context)
        } else {
          localPerson = Person.MR_findFirstOrCreateByAttribute("recordIDName",
            withValue: recordID.recordName,
            inContext: self.context)
        }
        
        let record = recordsByID![recordID]! 
        
        //set the returned properties
        if localPerson.valueForKey("firstName") as? String == nil {
          localPerson.setValue(record.objectForKey("FirstName") as? String, forKey: "firstName")
        }
        
        if localPerson.valueForKey("lastName") as? String == nil {
          localPerson.setValue(record.objectForKey("LastName") as? String, forKey: "lastName")
        }
        
        if localPerson.valueForKey("facebookID") as? String == nil {
          localPerson.setValue(record.objectForKey("FacebookID") as? String, forKey: "facebookID")

//            let predicate = NSPredicate(format: "FacebookID == %@", record.objectForKey("FacebookID") as! String)
//            let query = CKQuery(recordType: RecordTypes.Friends, predicate: predicate)
//            self.database.performQuery(query, inZoneWithID: nil, completionHandler: {
//                (friends: [CKRecord]?, error) -> Void in
//                logw("GetMissingPersonOperation Friends block")
//                for friend in friends! {
//                    let localFriendRecord = Friend.MR_findFirstOrCreateByAttribute("recordIDName", withValue: friend.recordID.recordName, inContext: self.context)
//                    if let facebookID = friend.objectForKey("FacebookID") {
//                        localFriendRecord.setValue(facebookID, forKey: "facebookID")
//                    }
//                    if let friendsFacebookID = friend.objectForKey("FriendsFacebookIDs") {
//                        localFriendRecord.setValue(friendsFacebookID, forKey: "friendsFacebookIDs")
//                    }
//                    let mutualFriends = Model.sharedInstance().getMutualFriendsFromLocal(localPerson, context: self.context)
//                    localPerson.setValue(mutualFriends.count, forKey: "mutualFriends")
//                }
//                self.context.MR_saveToPersistentStoreAndWait()
//            })
            
        }
        if localPerson.valueForKey("facebookID") as? String != nil{
            
            
            
            //old implementation ===============
//            Model.sharedInstance().getMutualFriendsFromFb(localPerson, context_: self.context, completionBlock: {
////                self.finish()
//                self.context.MR_saveToPersistentStoreAndWait()
//            })
            //==================================
            
            
            Model.sharedInstance().getTaggbleFriendsFromCloudAndMatch(localPerson, completionBlock: { taggableFriendsCount in
                localPerson.setValue(taggableFriendsCount, forKey: "mutualFriends")
                self.context.MR_saveToPersistentStoreAndWait()
                self.finish()
            })
            
            
        }
          //check for image property and set the data
//        if let imageAsset = recordsByID?[recordID]?.objectForKey("Image") as? CKAsset {
//          localPerson.setValue( NSData(contentsOfURL: imageAsset.fileURL), forKey: "image")
//        }
        if let imageUrlSuffix = record.objectForKey("ImageUrl") as? String {
            localPerson.setValue(imageUrlSuffix, forKey: "imageUrl")
        }
//        if let imageUrlSuffix = record.objectForKey("ImageUrl") as? String {
//            //download image
//            let downloadingFilePath = NSTemporaryDirectory()
//            let downloadRequest = Model.sharedInstance().downloadRequestForImageWithKey(imageUrlSuffix, downloadingFilePath: downloadingFilePath)
//            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//            let task = transferManager.download(downloadRequest)
//            task.continueWithBlock({ (task) -> AnyObject? in
//                if task.error != nil {
//                    logw("GetItemOperation image download failed with error: \(task.error!)")
//                } else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        let fileUrl = task.result!.valueForKey("body")!
//                        let modifiedUrl = Model.sharedInstance().filterUrlForDownload(fileUrl as! NSURL)
//                        localPerson.setValue(UIImagePNGRepresentation(UIImage(contentsOfFile: modifiedUrl)!) ,forKey: "image")
//                        self.context.MR_saveToPersistentStoreAndWait()
//                    }
//                }
//                return nil
//            })
//        }
        self.context.MR_saveToPersistentStoreAndWait()
      }
      
      //because the operations inside of the block wait, we can call finish outside of the block
      self.finish()
      
    }
    
    //add that operation to the operationQueue of self.database
    getPersonOperation.qualityOfService = qualityOfService
    self.database.addOperation(getPersonOperation)
    
  }

  override func finished(errors: [NSError]) {
    if errors.count != 0 {
      logw("GetAllPersonsWithMissingData finished with an error ")
    } else {
      logw("GetAllPersonsWithMissingData finished  ")
    }
  }
}