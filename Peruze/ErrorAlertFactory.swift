//
//  ErrorAlertFactory.swift
//  Peruze
//
//  Created by Phillip Trent on 7/13/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation

class ErrorAlertFactory: NSObject {
  class func alertFromError(error: NSError, dismissCompletion:(UIAlertAction! -> Void)? = nil) -> UIAlertController {
    
    let title = error.localizedDescription
    let first_message = error.localizedFailureReason ?? ""
    let second_message = error.localizedRecoverySuggestion ?? ""
    let message = first_message + " " + second_message
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: dismissCompletion))
    
    return alert
  }
  
  class func alertForNetworkWithTryAgainBlock(tryAgain:(Void -> Void)? = nil) -> UIAlertController {
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
  
  class func alertForiCloudSignIn() -> UIAlertController {
    let alert = UIAlertController(title: "Sign in to iCloud", message: "Peruze stores your data on iCloud so we can be sure that is is safe. Please sign in to your iCloud account on this device. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on.", preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "Got it!", style: .Cancel, handler: nil))
    return alert
  }
  
  class func locationEverywhereOnlyAccessAlert(actionCompletion: (Void -> Void)? = nil) -> UIAlertController {
    let message = "If you leave don't allow location services, your location will be anonymous, and only others who also have their range set to 'Everywhere' will be able to see your profile."
    return changeLocationAlert(message, completion: actionCompletion)
  }

  private class func changeLocationAlert(message: String, completion: (Void -> Void)?) -> UIAlertController {
    let title = "Can't Access Location"
    let cancelTitle = "Dismiss"
    let settingsTitle = "Settings"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      completion?()
    }
    let settingsAction = UIAlertAction(title: settingsTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
      completion?()
      UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
    alert.addAction(cancelAction)
    alert.addAction(settingsAction)
    return alert
  }
  
  class func friendSettingNoAccessAlert(completion: (Void -> Void)? = nil) -> UIAlertController {
    let message = "Because of your security settings, we can't see who your Facebook friends are! Without this access, we can't show you mutual friends on Peruze. You can change this in Settings later."
    return facebookFriendsAlert(message, completion: completion)
  }
  
  private class func facebookFriendsAlert(message: String, completion: (Void -> Void)?) -> UIAlertController {
    let title = "Can't Access Friends"
    let cancelTitle = "Dismiss"
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
      completion?()
    }
    alert.addAction(cancelAction)
    return alert
  }
  
  
  
  
}

