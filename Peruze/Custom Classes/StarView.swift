//
//  StarView.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
class StarView: UIView {
  
  private struct Constants {
    static let BufferSize: CGFloat = 0
  }
  
  private var starOne: UIImageView!
  private var starTwo: UIImageView!
  private var starThree: UIImageView!
  private var starFour: UIImageView!
  private var starFive: UIImageView!
  
  var numberOfStars: Float = 0 {
    didSet {
      if numberOfStars > 5 {
        numberOfStars = 5
      } else if numberOfStars < 0 {
        numberOfStars = 0
      }
      setNeedsDisplay()
    }
  }

  required init?(coder aDecoder: NSCoder) {
    starOne = UIImageView()
    starTwo = UIImageView()
    starThree = UIImageView()
    starFour = UIImageView()
    starFive = UIImageView()
    starOne.contentMode = .ScaleAspectFit
    starTwo.contentMode = .ScaleAspectFit
    starThree.contentMode = .ScaleAspectFit
    starFour.contentMode = .ScaleAspectFit
    starFive.contentMode = .ScaleAspectFit
    super.init(coder: aDecoder)
  }
  
  override func drawRect(rect: CGRect) {
    let sideLength = min(frame.height, frame.width / 5 - 4 * Constants.BufferSize)
    
    starThree.frame = CGRectMake(frame.width / 2 - sideLength / 2, frame.height / 2 - sideLength / 2, sideLength, sideLength)
    
    let top = starThree.frame.minY
    
    starTwo.frame = CGRectMake(starThree.frame.origin.x - sideLength - Constants.BufferSize, top, sideLength, sideLength)
    starOne.frame = CGRectMake(starTwo.frame.origin.x - sideLength - Constants.BufferSize, top, sideLength, sideLength)
    starFour.frame = CGRectMake(starThree.frame.maxX + Constants.BufferSize, top, sideLength, sideLength)
    starFive.frame = CGRectMake(starFour.frame.maxX + Constants.BufferSize, top, sideLength, sideLength)
    
    fillStarsWithNumber(numberOfStars)
    
    addSubview(starOne)
    addSubview(starTwo)
    addSubview(starThree)
    addSubview(starFour)
    addSubview(starFive)
  }
  
  func fillStarsWithNumber(numberOfStars: Float) {
    var numStars:Float = numberOfStars
    for star in [starOne, starTwo, starThree, starFour, starFive] {
      if numStars == 0.5 {
        star.image = UIImage(named: "Half_Star")
      } else if numStars > 0.5 {
        star.image = UIImage(named: "Full_Star")
      } else {
        star.image = UIImage(named: "Empty_Star")
      }
      --numStars
    }
  }
}
