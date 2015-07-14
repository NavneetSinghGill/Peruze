//
//  ErrorAlertFactory.swift
//  Peruze
//
//  Created by Phillip Trent on 7/13/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation

class ErrorAlertFactory: NSObject {
  class func AlertFromError(error: NSError, dismissCompletion:(UIAlertAction! -> Void)? = nil) -> UIAlertController {
    
    let title = error.localizedDescription
    let first_message = error.localizedFailureReason ?? ""
    let second_message = error.localizedRecoverySuggestion ?? ""
    let message = first_message + " " + second_message
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: dismissCompletion))
    
    return alert
  }
  
  class func AlertForNetworkWithTryAgainBlock(tryAgain:(Void -> Void)? = nil) -> UIAlertController {
    let alert = UIAlertController(title: "No Network Connection",
      message: "It looks like you aren't connected to the internet! Check your network settings and try again",
      preferredStyle: UIAlertControllerStyle.Alert)
    let dismiss = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil)
    let tryAgainAction = UIAlertAction(title: "Try Again", style: .Default) {(_) -> Void in
      tryAgain
    }
    alert.addAction(dismiss)
    if tryAgain != nil { alert.addAction(tryAgainAction) }
    return alert
  }
  
  class func AlertForiCloudSignIn() -> UIAlertController {
    let alert = UIAlertController(title: "Sign in to iCloud", message: "Peruze stores your data on iCloud so we can be sure that is is safe. Please sign in to your iCloud account on this device. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on.", preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "Got it!", style: .Cancel, handler: nil))
    return alert
  }
}

