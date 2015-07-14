//
//  NetworkConnection.swift
//  Peruse
//
//  Created by Phillip Trent on 7/9/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit
import SystemConfiguration

///domain for a network connection error
let NetworkErrorDomain = "NetworkErrorDomain"

class NetworkConnection: NSObject {
  //MARK: - Network Reachability
  class func connectedToNetwork() -> Bool {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
      SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
    }
    
    var flags : SCNetworkReachabilityFlags = 0
    if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
      return false
    }
    
    let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
  }
  class func defaultError() -> NSError {
    let domain = NetworkErrorDomain
    let code = 0
    let userInfo = [NSLocalizedDescriptionKey: "Network Error", NSLocalizedFailureReasonErrorKey: "Could not connect to the network.", NSLocalizedRecoverySuggestionErrorKey: "Please try again when you have a better network connection."]
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }
  
  
  //    SWIFT 2.0
  //
  //
  //    func connectedToNetwork() -> Bool {
  //
  //        var zeroAddress = sockaddr_in()
  //        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
  //        zeroAddress.sin_family = sa_family_t(AF_INET)
  //
  //        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
  //            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
  //        }) else {
  //            return false
  //        }
  //
  //        var flags : SCNetworkReachabilityFlags = []
  //        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
  //            return false
  //        }
  //
  //        let isReachable = flags.contains(.Reachable)
  //        let needsConnection = flags.contains(.ConnectionRequired)
  //        return (isReachable && !needsConnection)
  //    }
  
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
