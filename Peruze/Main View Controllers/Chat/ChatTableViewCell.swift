//
//  ChatTableViewCell.swift
//  Peruse
//
//  Created by Phillip Trent on 6/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ChatTableViewCell: UITableViewCell {
  var data: NSManagedObject? {
    didSet {
      //Swift 2.0
      guard
        let itemOffered = data?.valueForKey("itemOffered") as? NSManagedObject,
        let itemRequested = data?.valueForKey("itemRequested") as? NSManagedObject else {
          logw("Error: Issue with item data in ChatTableViewCell")
          return
      }
      
      guard
        let offeredImageData = itemOffered.valueForKey("image") as? NSData,
        let requestedImageData = itemRequested.valueForKey("image") as? NSData else {
          logw("Error: Issue with image data in ChatTableViewCell")
          return
      }
      
      guard
        let itemOfferedTitle = itemOffered.valueForKey("title") as? String,
        let itemRequestedTitle = itemRequested.valueForKey("title") as? String else {
          logw("Error: Issue with item title in ChatTableViewCell")
          return
      }
//      let fetchRequest = NSFetchRequest(entityName: "Message")
//        let exchangePredicate = NSPredicate(format: "exchange.recordIDName == %@", data?.valueForKey("recordIDName") as! String)
//        fetchRequest.predicate = exchangePredicate
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
//        fetchRequest.fetchLimit = 1
//        var fetchedResultsController: NSFetchedResultsController!
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedConcurrentObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//        do {
//            try fetchedResultsController.performFetch()
//            if fetchedResultsController.sections![0].numberOfObjects > 0 {
//                let latestChatArray : NSArray = fetchedResultsController.sections?[0].objects as! [Message]
//                let latestChat = latestChatArray[0]
//                if latestChat.valueForKey("sender") != nil && latestChat.valueForKey("sender")!.valueForKey("firstName") != nil && latestChat.valueForKey("sender")!.valueForKey("lastName") != nil{
//                   self.mostRecentTextString.text = "\(latestChat.valueForKey("sender")!.valueForKey("firstName")!) \(latestChat.valueForKey("sender")!.valueForKey("lastName")!): \(latestChat.valueForKey("text")!)"
//                }
//            } else {
//                self.mostRecentTextString.text = ""
//            }
//        } catch {
//            logw("ChatTableViewCell fetching latest chat failed with error: \(error)")
//        }
        itemImage.itemImages = (UIImage(data: offeredImageData)!, UIImage(data: requestedImageData)!)
      theirItemNameLabel.text = "\(itemOfferedTitle)"
      yourItemNameLabel.text = "for \(itemRequestedTitle)"
      
      //TODO: Uncomment this eventually
      //let name = data!.messages.last!.senderDisplayName == data!.exchage.itemRequested.owner.firstName ? "you" : "\(data!.messages.last!.senderDisplayName)"
      //mostRecentTextString.text = name + ": \(data!.messages.last!.text)"
    }
  }
  @IBOutlet weak var itemImage: DoubleCircleImage!
  @IBOutlet weak var theirItemNameLabel: UILabel!
  @IBOutlet weak var yourItemNameLabel: UILabel!
  @IBOutlet weak var mostRecentTextString: UILabel!
}
