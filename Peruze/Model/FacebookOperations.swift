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
import MagicalRecord

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
    let profileAlbum: AnyObject? = JSON.enumerateData(allAlbumData, forKey: "type", equalToValue: "profile")
    
    if cancelled { finish(); return [] }
    
    //find photo data in profile album
    let profileAlbumPhotoData: AnyObject = JSON.objectWithPathComponents(["photos", "data"], fromData: profileAlbum!)
    
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

/**
Fetches the currently logged in facebook user's profile and saves the information to disk
Produces an operation that saves the

*/
class FetchFacebookUserProfile: Operation {
  
  private struct Constants {
    static let ProfilePath = "me/?fields=id,last_name,first_name"
  }
  
  let context: NSManagedObjectContext
  let presentationContext: UIViewController
  
  init(presentationContext: UIViewController, context: NSManagedObjectContext = managedConcurrentObjectContext) {
    self.presentationContext = presentationContext
    self.context = context
    super.init()
  }
  
  override func execute() {
    let request = FBSDKGraphRequest(graphPath:Constants.ProfilePath, parameters: nil, HTTPMethod:"GET")
    dispatch_async(dispatch_get_main_queue()) {
      request.startWithCompletionHandler {(connection, result, error) -> Void in
        if error != nil {
          self.finishWithError(error)
          return
        }
        if let result = result as? [String: AnyObject] {
          let localMe = Person.MR_findFirstOrCreateByAttribute("me", withValue: true, inContext: self.context)
          localMe.firstName = result["first_name"] as? String
          localMe.lastName = result["last_name"] as? String
          localMe.facebookID = result["id"] as? String
          self.context.MR_saveToPersistentStoreAndWait()
        } else {
          let error = NSError(code: OperationErrorCode.ExecutionFailed)
          self.finishWithError(error)
          return
        }
        self.finish()
      }
    }
  }
  
  override func finished(errors: [NSError]) {
    if errors.first != nil {
      let alert = AlertOperation(presentationContext: presentationContext)
      alert.title = "Error Accessing Facebook"
      alert.message = "There was a problem accessing your general facebook information."
      produceOperation(alert)
    }
  }
  
}

///Fetches the currently logged in facebook user's profile
class FetchFacebookFriends: AsyncOperation {
  private struct Constants {
    static let ProfilePath = "me/?fields=friends.fields(id)"
  }
  
  var facebookIDs = [String]()
  
  override func main() {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    let request = FBSDKGraphRequest(graphPath:Constants.ProfilePath, parameters: nil, HTTPMethod:"GET")
    dispatch_async(dispatch_get_main_queue()) {
      request.startWithCompletionHandler {(connection, result, error) -> Void in
        if error != nil { self.error = error; self.finish(); return }
        /// array of dictionary objects each with a single "id" : "friendFacebookID" object
        let friendsData = JSON.objectWithPathComponents(["friends", "data"], fromData: result) as? [[String: AnyObject]]
        //add the facebook IDs to the whole facebook IDs
        self.facebookIDs = self.facebookIDs + self.facebookIDsFromArray(friendsData)
        //if there's a next string, there's more data to be retrieved
        if let nextURLString = JSON.objectWithPathComponents(["friends", "paging", "next"], fromData: result) as? String {
          if let nextURL = NSURL(string: nextURLString) {
            self.recursivelyPageDataFromURL(nextURL)
          } else {
            self.finish()
          }
        } else {
          self.finish()
        }
      }
    }
  }
  
  private func recursivelyPageDataFromURL(url: NSURL) {
    let getDataTask = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (resultData, resultResponse, resultError) -> Void in
      var jsonError: NSError?
      var jsonData: AnyObject?
//      Swift 2.0
//      do {
//        jsonData = try NSJSONSerialization.JSONObjectWithData(resultData!, options: .AllowFragments)
//      } catch let error as NSError {
//        jsonError = error
//        jsonData = nil
//      } catch {
//        fatalError()
//      }
      jsonData = NSJSONSerialization.JSONObjectWithData(resultData!, options: .AllowFragments, error: &jsonError)
      
      if jsonData == nil { self.finish(); return }
      if resultError != nil {
        self.error = resultError
        self.finish()
      } else if resultData != nil {
        let friendsData = JSON.objectWithPathComponents(["data"], fromData: jsonData!) as? [[String: AnyObject]]
        self.facebookIDs = self.facebookIDs + self.facebookIDsFromArray(friendsData)
      } else {
        self.finish()
      }
      if let nextURLString = JSON.objectWithPathComponents(["paging", "next"], fromData: jsonData!) as? String {
        if let nextURL = NSURL(string: nextURLString) {
          self.recursivelyPageDataFromURL(nextURL)
        } else {
          self.finish()
        }
      } else {
        self.finish()
      }
    })
    getDataTask.resume()
  }
  
  private func facebookIDsFromArray(array: [[String: AnyObject]]?) -> [String] {
    if array == nil { return [] }
    var returnArray = [String]()
    for obj in array! {
      if let facebookID = obj["id"] as? String {
        returnArray.append(facebookID)
      }
    }
    return returnArray
  }
}









