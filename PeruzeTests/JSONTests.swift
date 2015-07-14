//
//  JSONTests.swift
//  Peruze
//
//  Created by Phillip Trent on 7/14/15.
//  Copyright (c) 2015 Peruze, LLC. All rights reserved.
//

import UIKit
import XCTest
//import Peruze
//
//class JSONTests: XCTestCase {
//  let dictArray: AnyObject = ["firstLevel":[1, 2, 3, 4],
//    "secondLevel":[2, 4, 6],
//    "thirdLevel": [3, 6],
//    "fourthLevel": [4, 8, 12]]
//  let arrayDict: AnyObject = [["A": "1", "B": "2", "C": "3"], ["A": "Apple", "B": "Banana"], ["A": "Animal", "B": "Bryophyte", "D": "Dendrites"], ["A": "Appleseed", "B": "Bryan", "C": "Clary", "D": "Damien"]]
//  
//  func testJSONPathComponents() {
//    let message = "JSON object with path components failed"
//    
//    let resultOne = JSON.objectWithPathComponents(["firstLevel"], fromData: dictArray) as! NSObject
//    let resultTwo = JSON.objectWithPathComponents(["secondLevel"], fromData: dictArray) as! NSObject
//    let resultThree = JSON.objectWithPathComponents(["thirdLevel"], fromData: dictArray) as! NSObject
//    let resultFour = JSON.objectWithPathComponents(["fourthLevel"], fromData: dictArray) as! NSObject
//    XCTAssertEqual([1, 2, 3, 4], resultOne, message)
//    XCTAssertEqual([2, 4, 6], resultTwo, message)
//    XCTAssertEqual([3, 6], resultThree, message)
//    XCTAssertEqual([4, 8, 12], resultFour, message)
//    
//  }
//  
//  func testJSONPathComponentsPerformance() {
//    self.measureBlock() {
//      
//      let resultOne = JSON.objectWithPathComponents(["firstLevel"], fromData: self.dictArray) as! NSObject
//      XCTAssertEqual([1, 2, 3, 4], resultOne)
//      
//    }
//  }
//  
//  func testJSONEnumerate() {
//    let message = "JSON enumerate objects failed"
//    
//    let resultOne: AnyObject = JSON.enumerateData(arrayDict, forKey: "A", equalToValue: "1")
//    let resultTwo: AnyObject = JSON.enumerateData(arrayDict, forKey: "A", equalToValue: "Apple")
//    let resultThree: AnyObject = JSON.enumerateData(arrayDict, forKey: "A", equalToValue: "Animal")
//    let resultFour: AnyObject = JSON.enumerateData(arrayDict, forKey: "A", equalToValue: "Appleseed")
//    
//    XCTAssertEqual("2", resultOne["B"] as! String, message)
//    XCTAssertEqual("Banana", resultTwo["B"] as! String, message)
//    XCTAssertEqual("Bryophyte", resultThree["B"] as! String, message)
//    XCTAssertEqual("Bryan", resultFour["B"] as! String, message)
//    
//  }
//  
//  func testJSONEnumeratePerformance() {
//    self.measureBlock() {
//      
//      let resultOne: AnyObject = JSON.enumerateData(self.arrayDict, forKey: "A", equalToValue: "1")
//      XCTAssertEqual("2", resultOne["B"] as! String)
//      
//    }
//  }
//  
//}

