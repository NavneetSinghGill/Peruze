//
//  FileManagementOperations.swift
//  Peruse
//
//  Created by Phillip Trent on 7/12/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import Foundation
import AsyncOpKit

let WriteFileErrorDomain = "Error Writing File"
let ReadFileErrorDomain = "Error Reading File"

class WritePNGImageToPath: AsyncOperation {
  private let image: UIImage
  private let path: String
  
  init(image: UIImage, path: String) {
    self.image = image
    self.path = path
    super.init()
  }
  
  override func main() {
    let pngData = UIImagePNGRepresentation(image)
    if cancelled { finish() ; return }
    if !pngData.writeToFile(path, atomically: true) {
      error = NSError(domain: WriteFileErrorDomain,
        code: 0,
        userInfo: [
          NSLocalizedDescriptionKey: "Error Writing File",
          NSLocalizedFailureReasonErrorKey: "There was a problem writing an image to your phone's storage. ",
          NSLocalizedRecoverySuggestionErrorKey: "Close and reopen the application. "
        ]
      )
    }
    finish()
  }
}

class RemoveFileAtPath: AsyncOperation {
  private let path: String
  init(path: String) {
    self.path = path
    super.init()
  }
  override func main() {
    NSFileManager.defaultManager().removeItemAtPath(path, error: &error)
    finish()
  }
}

