//
//  FacebookDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/7/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import AsyncOpKit

protocol FacebookProfilePictureRetrievalDelegate {
  var profileImages: [UIImage]? { get set }
  var percentLoaded: Int? { get set } //out of 100%
}


class FacebookDataSource: NSObject {
  private struct Constants {
    static let NumberOfPicturesToRetrieve = 4
    static let ConnectionTimeout: Double = 10
    static let GraphPath = "me/?fields=albums.fields(type,photos.limit(\(NumberOfPicturesToRetrieve)).fields(images))"
    static let ProfilePath = "me/?fields=id,last_name,first_name"
  }
  var profilePictureRetrievalDelegate: FacebookProfilePictureRetrievalDelegate?
  
  func getProfilePhotosWithCompletion(completionBlock: ((success: Bool, error: NSError?) -> Void)) {
    
    //make sure there is a network connection
    if !NetworkConnection.connectedToNetwork() {
      completionBlock(success: false, error: NetworkConnection.defaultError())
      return
    }
    //setup the operations
    let startIndicator = StartNetworkIndicator()
    let stopIndicator = StopNetworkIndicator()
    let downloadURLOperation = DownloadProfilePhotoURLs()
    let downloadImageOperation = DownloadImagesForURLs()
    let downloadErrorHandler = { (operation: AsyncOperation) -> Void in
      if operation.error != nil {
        dispatch_async(dispatch_get_main_queue(), {
          completionBlock(success: false, error: operation.error)
        })
        return
      }
      if let imagesOp = operation as? DownloadImagesForURLs {
        completionBlock(success: true, error: nil)
        self.profilePictureRetrievalDelegate?.profileImages = imagesOp.images
      }
    }
    
    //add error and completion handling
    downloadURLOperation.completionHandler = downloadErrorHandler
    downloadImageOperation.completionHandler = downloadErrorHandler
    
    //add dependencies
    downloadURLOperation.addDependency(startIndicator)
    downloadImageOperation.addDependency(downloadURLOperation)
    stopIndicator.addDependency(downloadImageOperation)
    
    NSOperationQueue.mainQueue().addOperations(
      [startIndicator,
        downloadURLOperation,
        downloadImageOperation,
        stopIndicator],
      waitUntilFinished: false)
  }
  
  class func getUserProfileWithCompletion(completion: ((result: FBSDKProfile?, error: NSError?) -> Void)) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    let request = FBSDKGraphRequest(graphPath:Constants.ProfilePath, parameters: nil, HTTPMethod:"GET")
    dispatch_async(dispatch_get_main_queue()) {
      request.startWithCompletionHandler {(connection, result, error) -> Void in
        if error != nil {
          print(error.localizedDescription)
          return
        }
        var profile: FBSDKProfile?
        if let _ = result as? [String: AnyObject] {
          profile = FBSDKProfile(userID: result["id"] as! String,
            firstName: result["first_name"] as! String,
            middleName: nil,
            lastName: result["last_name"] as! String,
            name: nil,
            linkURL: nil,
            refreshDate: nil)
        } else {
          print("result is not a [String: AnyObject] dictionary")
        }
        dispatch_async(dispatch_get_main_queue()) {
          UIApplication.sharedApplication().networkActivityIndicatorVisible = false
          completion(result: profile, error: error)
        }
      }
    }
  }
}
