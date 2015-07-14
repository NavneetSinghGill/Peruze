//
//  LoadingCircleView.swift
//  Peruse
//
//  Created by Phillip Trent on 6/7/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

@IBDesignable
class LoadingCircleView: UIView {
    var strokeWidth: CGFloat = 1
    var hidesWhenStopped = true
    var animating = false
    var fullRotationCompletionDuration: NSTimeInterval = 1.0
    var fadeOutAnimationDuration: NSTimeInterval = 0.25
    private struct Constants {
        static let EndAngle: CGFloat = CGFloat(7 * M_PI / 4)
        static let StartAnge: CGFloat = 0
        static let Delay: NSTimeInterval = 0
    }
    
    func start() {
        setNeedsDisplay()
        alpha = 1.0
        if !animating {
            animating = true
        }
        
        UIView.animateWithDuration(fullRotationCompletionDuration,
            delay: Constants.Delay,
            options: .CurveLinear,
            animations: {[unowned self] () -> Void in
                self.transform = CGAffineTransformRotate(self.transform, CGFloat(M_PI / 2))
                return
        }) { (success) -> Void in
            if (success && self.animating) {
                self.start()
            }
            return
        }
    }
    
    func stop() {
        if hidesWhenStopped {
            UIView.animateWithDuration(fadeOutAnimationDuration) {
                self.alpha = 0.0
            }
        }
        self.animating = false
    }
    
    override func drawRect(rect: CGRect) {
        backgroundColor = UIColor.clearColor()
        let circleCenter = CGPointMake(bounds.width / 2, bounds.height / 2)
        let path = UIBezierPath(arcCenter: circleCenter, radius: bounds.width / 2 - strokeWidth, startAngle: Constants.StartAnge, endAngle: Constants.EndAngle, clockwise: true)
        path.lineWidth = strokeWidth
        UIColor.blackColor().setStroke()
        path.stroke()
    }
}
