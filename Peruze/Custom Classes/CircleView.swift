//
//  CircleView.swift
//  Peruse
//
//  Created by Phillip Trent on 5/30/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

@IBDesignable
class CircleView: UIView {
    var strokeWidth:CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    var strokeColor: UIColor = .blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    var fillColor: UIColor = .blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    var fillCircle = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var halfCircle = false {
        didSet {
            setNeedsDisplay()
        }
    }
    override func drawRect(rect: CGRect) {
        opaque = false
        backgroundColor = .clearColor()
        let sideLength: CGFloat = bounds.width - strokeWidth * 2
        let circleFrame = CGRectMake(strokeWidth, strokeWidth, sideLength, sideLength)
        var path = UIBezierPath(ovalInRect: circleFrame)
        if halfCircle {
            let center = CGPointMake(sideLength / 2 + circleFrame.origin.x, sideLength / 2 + circleFrame.origin.y)
            path = UIBezierPath(arcCenter: center, radius: sideLength / 2, startAngle: 0, endAngle: CGFloat(M_PI), clockwise: true)
        }
        path.lineWidth = strokeWidth
        strokeColor.setStroke()
        path.stroke()
        if fillCircle {
            fillColor.setFill()
            path.fill()
        }
    }

}
