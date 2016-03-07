//
//  NetworkConnection.swift
//  Peruse
//
//  Created by Phillip Trent on 7/9/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import SystemConfiguration
import SwiftLog

///domain for a network connection error
let NetworkErrorDomain = "NetworkErrorDomain"

class NetworkConnection: NSObject {
  //MARK: - Network Reachability
  
  class func defaultError() -> NSError {
    let domain = NetworkErrorDomain
    let code = 0
    let userInfo = [NSLocalizedDescriptionKey: "Network Error", NSLocalizedFailureReasonErrorKey: "Could not connect to the network.", NSLocalizedRecoverySuggestionErrorKey: "Please try again when you have a better network connection."]
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }
  
  class func connectedToNetwork() -> Bool {
    
    var status = false
    let url = NSURL(string: "http://google.com/")
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "HEAD"
    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
    request.timeoutInterval = 10.0
    
    var response: NSURLResponse?
    do {
    let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response) as? NSData
    } catch {
      logw("ConnectedToNetwork: \(error)")
    }
    if let httpResponse = response as? NSHTTPURLResponse {
      if httpResponse.statusCode == 200 {
        status = true
      }
    }
    logw("ConnectedToNetwork: \(status)")
    return status
  }
  
}

class StartNetworkIndicator: NSOperation {
  override func main() {
    dispatch_async(dispatch_get_main_queue()) {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
  }
}

class StopNetworkIndicator: NSOperation {
  override func main() {
    dispatch_async(dispatch_get_main_queue()) {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
  }
}
