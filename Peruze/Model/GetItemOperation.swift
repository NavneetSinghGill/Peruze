//
//  GetItemOperation.swift
//  Peruze
//
//  Created by Phillip Trent on 7/22/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import MagicalRecord
import CloudKit

class GetItemOperation: Operation {
  
  let context: NSManagedObjectContext
  let database: CKDatabase
  
  init(database: CKDatabase, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.database = database
    self.context = context
    super.init()
  }
  
  override func execute() {
    print("execute item fetch")
    defer {
      self.context.MR_saveToPersistentStoreAndWait()
    }
    
    let allItemsPredicate = NSPredicate(format: "recordIDName != nil AND image == nil")
    guard let allItems = Item.MR_findAllWithPredicate(allItemsPredicate, inContext: context) as? [NSManagedObject] else {
      print("Get Item Operation could not cast returned objects as [NSManagedObject]")
      self.finish()
      return
    }
    
    let allRecordIDNames = allItems.map { $0.valueForKey("recordIDName") as? String }
    
    var itemRecordsToFetch = [CKRecordID]()
    for itemRecordIDName in allRecordIDNames where itemRecordIDName != nil {
      itemRecordsToFetch.append(CKRecordID(recordName: itemRecordIDName!))
    }
    
    let fetchAllItemsOperation = CKFetchRecordsOperation(recordIDs: itemRecordsToFetch)
    fetchAllItemsOperation.fetchRecordsCompletionBlock = { (recordsByID, error) -> Void in
      if error != nil {
        print("FETCH ALL ITEMS RETURNED ERROR: \(error)")
      }
      //make sure the recordsByID are not nil
      if let recordsByID = recordsByID {
        
        MagicalRecord.saveWithBlockAndWait { (context) -> Void in
          
          //for each record that is returned
          for recordID in recordsByID.keys {
            
            //get a local copy of the item to save
            let localItem = Item.MR_findFirstOrCreateByAttribute("recordIDName",
              withValue: recordID.recordName,
              inContext: context)
            
            //get image
            if let image = recordsByID[recordID]!.valueForKey("Image") as? CKAsset {
              localItem.image = NSData(contentsOfURL: image.fileURL)
            } else {
              print("Image is not a CKAsset")
            }
            
            //get title
            if let title = recordsByID[recordID]!.valueForKey("Title") as? String {
              localItem.setValue(title, forKey: "title")
            } else {
              print("Title is not a String")
            }

            
            //get detail
            if let description = recordsByID[recordID]!.valueForKey("Description") as? String {
              localItem.detail = description
            } else {
              print("Description is not a String")
            }

            
            //fill in creator details
            if let creator = recordsByID[recordID]!.creatorUserRecordID {
              localItem.owner = Person.MR_findFirstOrCreateByAttribute("recordIDName",
                withValue: creator.recordName,
                inContext: context)
              if let facebookID = recordsByID[recordID]!.valueForKey("OwnerFacebookID") as? String {
                localItem.owner!.facebookID = facebookID
              } else {
                print("OwnerFacebookID is not a String")
              }

            } else {
              print("creator is nil")
            }
          }
        }
      }
      self.finishWithError(error)
    }
    database.addOperation(fetchAllItemsOperation)
  }
}