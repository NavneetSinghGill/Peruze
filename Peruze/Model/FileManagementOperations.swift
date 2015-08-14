//
//  FileManagementOperations.swift
//  Peruse
//
//  Created by Phillip Trent on 7/12/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation

let WriteFileErrorDomain = "Error Writing File"
let ReadFileErrorDomain = "Error Reading File"

class WritePNGImageToPath: Operation {
  private let image: UIImage
  private let path: String
  
  init(image: UIImage, path: String) {
    self.image = image
    self.path = path
    super.init()
  }
  override func execute() {
    let pngData = UIImagePNGRepresentation(image)
    if !pngData!.writeToFile(path, atomically: true) {
      let error = NSError(domain: WriteFileErrorDomain,
        code: 0,
        userInfo: [
          NSLocalizedDescriptionKey: "Error Writing File",
          NSLocalizedFailureReasonErrorKey: "There was a problem writing an image to your phone's storage. ",
          NSLocalizedRecoverySuggestionErrorKey: "Close and reopen the application. "
        ]
      )
      self.finish(GenericError.ExecutionFailed)
    } else {
      finish()
    }
  }
}

class RemoveFileAtPath: AsyncOperation {
  private let path: String
  init(path: String) {
    self.path = path
    super.init()
  }
  override func main() {
//    do {
//      try NSFileManager.defaultManager().removeItemAtPath(path)
//    } catch let error1 as NSError {
//      error = error1
//    }
    var error: NSError?
    NSFileManager.defaultManager().removeItemAtPath(path, error: &error)
    if error != nil { print(error) }
    finish()
  }
}

