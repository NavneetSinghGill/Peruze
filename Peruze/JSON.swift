//
//  JSON.swift
//  Peruse
//
//  Created by Phillip Trent on 6/10/15.
//  Copyright © 2015 Phillip Trent. All rights reserved.
//

import UIKit

public class JSON: NSObject {
    class func objectWithPathComponents(components: [String], fromData data: AnyObject) -> AnyObject {
        var currentNode: AnyObject = data
        for pathEdge in components {
            if let node = currentNode as? [String: AnyObject] {
                if let value: AnyObject = node[pathEdge] {
                    currentNode = value
                } else {
                    println("There is no \(pathEdge) directory in given data")
                }
            }
        }
        return currentNode
    }
    
    class func enumerateData(data: AnyObject, forKey key: String, equalToValue value: String) -> AnyObject {
        if let enumerable = data as? [[String: AnyObject]] {
            var results: AnyObject?
            for obj in enumerable {
                if let objValue = obj[key] as? String {
                    if objValue == value {
                        results = obj
                    }
                }
            }
            return results!
        } else {
            return ""
        }
    }
}
