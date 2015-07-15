//
//  FacebookOperations.swift
//  Peruse
//
//  Created by Phillip Trent on 7/11/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation
import AsyncOpKit
import FBSDKCoreKit

//MARK: - Download Profile Photo

/**
Operation that downloads the urls for the currently
authenticated Facebook user's most recent profile photos
*/
class DownloadProfilePhotoURLs: AsyncOperation {
  //Define Constants
  private struct Constants {
    static let NumberOfPicturesToRetrieve = 4
    static let GraphPath = "me/?fields=albums.fields(type,photos.limit(\(NumberOfPicturesToRetrieve)).fields(images))"
  }
  
  ///resulting array of image URLs
  var imageURLs = [NSURL]()
  
  override func main() {
    if cancelled { finish(); return }
    //create the request from above graph path
    let request = FBSDKGraphRequest(graphPath:Constants.GraphPath, parameters: nil, HTTPMethod:"GET")
    request.startWithCompletionHandler {[unowned self] (connection, result, error) -> Void in
      //set error and return
      self.error = error
      if error != nil { self.finish(); return }
      self.imageURLs = self.parseImageURLsFromResult(result)
      self.finish()
    }
  }
  
  private func parseImageURLsFromResult(result: AnyObject) -> [NSURL] {
    var returnURLs = [NSURL]()
    
    if cancelled { finish(); return [] }
    
    //get all album data
    let allAlbumData: AnyObject = JSON.objectWithPathComponents(["albums", "data"], fromData: result)
    
    if cancelled { finish(); return [] }
    
    //find profile album
    let profileAlbum: AnyObject = JSON.enumerateData(allAlbumData, forKey: "type", equalToValue: "profile")
    
    if cancelled { finish(); return [] }
    
    //find photo data in profile album
    let profileAlbumPhotoData: AnyObject = JSON.objectWithPathComponents(["photos", "data"], fromData: profileAlbum)
    
    if cancelled { finish(); return [] }
    
    //parse out URLs from photo data
    let albumData = profileAlbumPhotoData as? [[String: AnyObject]]
    assert(albumData != nil, "Album Data pulled from graph path is nil")
    
    if cancelled { finish(); return [] }
    
    for dict in albumData! {
      
      if cancelled { finish(); return [] }
      
      let allURLsForAllImageSizes: AnyObject = JSON.objectWithPathComponents(["images"], fromData: dict)
      
      if cancelled { finish(); return [] }
      
      if let allURLImageSizes = allURLsForAllImageSizes as? [[String: AnyObject]] {
        
        if cancelled { finish(); return [] }
        
        returnURLs.append(NSURL(string: allURLImageSizes.first!["source"] as! String)!)
      }
    }
    return returnURLs
  }
}


/**
Operation that downloads the images corresponding to an array of NSURL
objects. You can access the images array by adding a completion
handler to the AsyncOperation Object and downcasting the result
to a DownloadImagesForURLs
*/
class DownloadImagesForURLs: AsyncOperation {
  ///Image URLs from dependencies
  private var imageURLs = [NSURL]()
  ///Images that are
  var images = [UIImage]()
  
  override func main() {
    
    //get image URLs from dependencies
    for dependency in self.dependencies {
      if let downloadURLDependency = dependency as? DownloadProfilePhotoURLs {
        self.imageURLs = self.imageURLs + downloadURLDependency.imageURLs
      }
    }
    
    var data = [NSData]()
    
    //populate the data from the URLs
    for url in imageURLs {
      if cancelled { finish(); return }
      data.append(NSData(contentsOfURL: url)!)
    }
    
    //check cancel state
    if cancelled { finish(); return }
    
    //populate the image array with images from the data
    for imgData in data {
      if cancelled { finish(); return }
      if let image = UIImage(data: imgData) {
        images.append(image)
      } else {
        cancel()
      }
    }
    finish()
  }
}

///Fetches the currently logged in facebook user's profile
class FetchFacebookUserProfile: AsyncOperation {
  private struct Constants {
    static let ProfilePath = "me/?fields=id,last_name,first_name"
  }
  var profile: FBSDKProfile?
  
  override func main() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    var request = FBSDKGraphRequest(graphPath:Constants.ProfilePath, parameters: nil, HTTPMethod:"GET")
    
    dispatch_async(dispatch_get_main_queue()) {
      request.startWithCompletionHandler {(connection, result, error) -> Void in
        if error != nil { self.error = error; self.finish(); return }
        
        if let dictRepresentation = result as? [String: AnyObject] {
          self.profile = FBSDKProfile(userID: result["id"] as! String,
            firstName: result["first_name"] as! String,
            middleName: nil,
            lastName: result["last_name"] as! String,
            name: nil,
            linkURL: nil,
            refreshDate: nil)
        }
        dispatch_async(dispatch_get_main_queue()) {
          UIApplication.sharedApplication().networkActivityIndicatorVisible = false
          self.finish()
        }
      }
    }
  }
}









