//
//  CircleImage.swift
//  Peruse
//
//  Created by Phillip Trent on 5/26/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

@IBDesignable
public class CircleImage: UIView {
    //MARK: - Variables
    @IBInspectable public var image: UIImage? {
        didSet {
            if imageView != nil { imageView!.image = image }
            else { imageView = UIImageView(image: image) }
            setNeedsDisplay()
        }
    }
    public var strokeWidth: CGFloat = 0 { didSet { setNeedsDisplay() } }
    public var selected = false { didSet { setNeedsDisplay() } }
    private var imageView: UIImageView?
    private var circleView: UIView?
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clearColor()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
  
    //MARK: - Drawing
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        drawDisk(selected)
        
        //setup the imageview
        self.backgroundColor = UIColor.clearColor()
        if image == nil {
            image = UIImage()
        }
        imageView = imageView ?? UIImageView(image: image)
        imageView!.frame = CGRectMake(0, 0, frame.width, frame.height)
        imageView!.contentMode = .ScaleAspectFill
        addSubview(imageView!)
        
        //create the mask
        let width = Float(bounds.width) - Float(strokeWidth) * 2
        let height = Float(bounds.height) - Float(strokeWidth) * 2
        let maskFrame = CGRectMake(strokeWidth, strokeWidth, CGFloat(width), CGFloat(height))
        let path = UIBezierPath(ovalInRect: maskFrame)
        let mask = CAShapeLayer()
        mask.path = path.CGPath
        imageView!.layer.mask = mask
    }
    
    private func drawDisk(draw: Bool) {
        if draw {
            circleView = circleView ?? UIView()
            circleView!.backgroundColor = UIColor.blackColor()
            circleView!.frame = CGRectMake(0, 0, bounds.width, bounds.height)
            circleView!.layer.cornerRadius = (bounds.width + bounds.height) / 4
            addSubview(circleView!)
        } else {
            circleView?.removeFromSuperview()
        }
    }
}
