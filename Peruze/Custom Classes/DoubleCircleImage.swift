//
//  DoubleCircleImage.swift
//  Peruse
//
//  Created by Phillip Trent on 6/19/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class DoubleCircleImage: UIView {
    //TODO: Delete big and little image. they're just for design purposes
    
    var itemImages: (prominentImage: UIImage, lesserImage: UIImage)? {
        didSet {
            prominentImage?.image = itemImages?.prominentImage
            lesserImage?.image = itemImages?.lesserImage
            setNeedsDisplay()
        }
    }
    
    private var prominentImage: CircleImage?
    private var lesserImage: CircleImage?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        lesserImage = CircleImage()
        lesserImage!.image = itemImages?.lesserImage
        lesserImage!.backgroundColor = .clearColor()
        addSubview(lesserImage!)
        prominentImage = CircleImage()
        prominentImage!.image = itemImages?.prominentImage
        prominentImage!.backgroundColor = .clearColor()
        addSubview(prominentImage!)
        backgroundColor = .clearColor()
        
    }
    override func drawRect(rect: CGRect) {
        let sideLength = min(frame.height, frame.width)
        lesserImage!.frame = CGRectMake(0, 0, sideLength / 2, sideLength / 2)
        prominentImage!.frame =  CGRectMake(sideLength / 4, sideLength / 4, (3/4) * sideLength, (3/4) * sideLength)
    }
}
