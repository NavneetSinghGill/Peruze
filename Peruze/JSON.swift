//
//  JSON.swift
//  Peruse
//
//  Created by Phillip Trent on 6/10/15.
//  Copyright © 2015 Phillip Trent. All rights reserved.
//

import UIKit

public class JSON: NSObject {
  /**
  Returns the objet at the end of the specified path components in the given `data`
  
  - parameter components: The components of the path for example: /friends/data/images would be represented as [friends, data, images]
  - parameter data: The data passed in nested with the path components
  
  - returns: The data at the end of a specified path. For example /friends/data/images would return whatever data corresponds to the 'images' key
  */
  class func objectWithPathComponents(components: [String], fromData data: AnyObject) -> AnyObject {
    var currentNode: AnyObject = data
    for pathEdge in components {
      if let node = currentNode as? [String: AnyObject] {
        if let value: AnyObject = node[pathEdge] {
          currentNode = value
        } else {
          print("There is no \(pathEdge) directory in given data")
        }
      }
    }
    return currentNode
  }
  /**
    Searches through `data` as a [[String: AnyObject]] array for a `key` and then returns the associated value
  
    :data: data The data to enumerate through. Must be [[String: AnyObject]]
    :key: key The key to search through in the array of data
  
    - returns: The value matching the given `key` or `nil` if the value doesn't exist
  */
  class func enumerateData(data: AnyObject, forKey key: String, equalToValue value: String) -> AnyObject? {
    var results: AnyObject?
    if let enumerable = data as? [[String: AnyObject]] {
      for obj in enumerable {
        if let objValue = obj[key] as? String {
          if objValue == value {
            results = obj
          }
        }
      }
    }
    return results
  }
}
