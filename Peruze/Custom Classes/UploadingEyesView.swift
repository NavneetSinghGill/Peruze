//
//  UploadingEyesView.swift
//  Peruse
//
//  Created by Phillip Trent on 6/30/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit

class UploadingEyesView: UIView {
    private struct Constants {
        static let BufferSpace: CGFloat = 8
        static let UploadingFontSize: CGFloat = 32
        static let EyepieceStrokeWidth: CGFloat = 2
        static let UploadingAnimationDuration: NSTimeInterval = 0.25
        static let UploadingAnimationDelay: NSTimeInterval = 1.0
    }
    
    //MARK: - Upload Drawing Methods
    private enum EyeDirection {
        case North
        case NorthEast
        case East
        case SouthEast
        case South
        case SouthWest
        case West
        case NorthWest
        case Center
    }
    //MARK: Variables
    private var animating = false
    private var eyepiece: CircleView?
    private var rightReference: CircleView?
    private var pupils: (left: CircleView, right: CircleView)?
    private var blurBackgroundView: UIVisualEffectView?
    private var vibrantBackgroundView: UIVisualEffectView?
    private var uploadingLabel: UILabel?
    
    //MARK: Setup Methods
    func beginUpload() {
        animating = true
        blurBackground()
        createUploadingLabel()
        createEyepiece()
        createPupils()
        moveEyesTo(.Center, completion: nil)
    }
    
    private func blurBackground() {
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        blurBackgroundView = UIVisualEffectView(effect: blurEffect)
        blurBackgroundView!.frame = CGRectMake(0, 0, frame.width, frame.height)
        blurBackgroundView!.alpha = 0.0
        vibrantBackgroundView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        vibrantBackgroundView!.frame = blurBackgroundView!.frame
        blurBackgroundView!.contentView.addSubview(vibrantBackgroundView!)
        addSubview(blurBackgroundView!)
        UIView.animateWithDuration(Constants.UploadingAnimationDuration){
            self.blurBackgroundView!.alpha = 1.0
        }
    }
    
    private func createUploadingLabel() {
        let labelX = Constants.BufferSpace
        let labelY = Constants.BufferSpace
        let labelWidth = frame.width - Constants.BufferSpace * 2
        let labelHeight = frame.height / 6
        let labelFrame = CGRectMake(labelX, labelY, labelWidth, labelHeight)
        uploadingLabel = UILabel(frame: labelFrame)
        uploadingLabel!.text = "Uploading"
        uploadingLabel!.font = UIFont.systemFontOfSize(Constants.UploadingFontSize, weight: UIFontWeightThin)
        uploadingLabel!.textAlignment = .Center
        
        vibrantBackgroundView!.contentView.addSubview(uploadingLabel!)
    }
    
    private func createEyepiece() {
        let eyepieceX = uploadingLabel!.frame.minX
        let eyepieceY = uploadingLabel!.frame.maxY + Constants.BufferSpace
        let eyepieceSideLength = min(frame.height / 2  - eyepieceY , frame.width / 2)
        let eyepieceFrame = CGRectMake(eyepieceX, eyepieceY, eyepieceSideLength, eyepieceSideLength)
        eyepiece = CircleView(frame: eyepieceFrame)
        eyepiece!.strokeColor = .blackColor()
        eyepiece!.strokeWidth = Constants.EyepieceStrokeWidth
        eyepiece!.backgroundColor = .clearColor()
        blurBackgroundView!.contentView.addSubview(eyepiece!)
        
        let rightReferenceX = frame.width - eyepieceX - eyepieceSideLength
        let referenceFrame = CGRectMake(rightReferenceX, eyepieceY, eyepieceSideLength, eyepieceSideLength)
        rightReference = CircleView(frame: referenceFrame)
    }
    
    private func createPupils() {
        let pupilSideLength = eyepiece!.frame.width / 3
        let leftPupil = CircleView(frame: CGRectMake(0, 0, pupilSideLength, pupilSideLength))
        leftPupil.fillCircle = true
        leftPupil.fillColor = .blackColor()
        leftPupil.backgroundColor = .clearColor()
        leftPupil.center = eyepiece!.center
        
        let rightPupil = CircleView(frame: CGRectMake(0, 0, pupilSideLength, pupilSideLength))
        rightPupil.fillCircle = true
        rightPupil.fillColor = .blackColor()
        rightPupil.backgroundColor = .clearColor()
        rightPupil.center = rightReference!.center
        
        pupils = (leftPupil, rightPupil)
        blurBackgroundView!.contentView.addSubview(leftPupil)
        blurBackgroundView!.contentView.addSubview(rightPupil)
    }
    
    private func moveEyesTo(location: EyeDirection, completion: (Void -> Void)?) {
        var multiplierX:CGFloat = 0
        var multiplierY:CGFloat = 0
        let pupilTransAmount = pupils!.left.frame.height / 2
        
        switch location {
        case .North:
            (multiplierX, multiplierY) = (0, -1)
            break
        case .NorthEast:
            (multiplierX, multiplierY) = (1, -1)
            break
        case .East:
            (multiplierX, multiplierY) = (1, 0)
            break
        case .SouthEast:
            (multiplierX, multiplierY) = (1, 1)
            break
        case .South:
            (multiplierX, multiplierY) = (0, 1)
            break
        case .SouthWest:
            (multiplierX, multiplierY) = (-1, 1)
            break
        case .West:
            (multiplierX, multiplierY) = (-1, 0)
            break
        case .NorthWest:
            (multiplierX, multiplierY) = (-1, -1)
            break
        case .Center:
            (multiplierX, multiplierY) = (0, 0)
            break
        }
        
        let xTranslation = pupilTransAmount * multiplierX
        let yTranslation = pupilTransAmount * multiplierY
        let leftCoords = CGPointMake(eyepiece!.center.x + xTranslation, eyepiece!.center.y + yTranslation)
        let rightCoords = CGPointMake(rightReference!.center.x + xTranslation, rightReference!.center.y + yTranslation)
        UIView.animateWithDuration(Constants.UploadingAnimationDuration,
            delay: Constants.UploadingAnimationDelay,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                (self.pupils!.left.center, self.pupils!.right.center) = (leftCoords, rightCoords)
            }) { (success) -> Void in
                if self.animating && success {
                    self.moveEyesTo(self.randomEyeDirection(), completion: nil)
                } else {
                    self.endUploadAnimationsFinished(completion)
                }
        }
    }
    //MARK: Tear Down Methods
    //TODO: Make this private
    func endUpload(completion: (Void -> Void)?) {
        animating = false
        moveEyesTo(EyeDirection.Center, completion: completion)
    }
    private func endUploadAnimationsFinished(completion: (Void -> Void)?) {
        uploadingLabel!.removeFromSuperview()
        blurBackgroundView!.contentView.addSubview(uploadingLabel!)
        uploadingLabel!.text = "Done!"
        createSmile()
        UIView.animateWithDuration(Constants.UploadingAnimationDuration, delay: Constants.UploadingAnimationDelay * 2, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.blurBackgroundView!.alpha = 0.0
            }) { (success) -> Void in
                completion?()
        }
    }
    private func createSmile() {
        let pupilSideLength = pupils!.left.frame.height
        let arcX = frame.width / 2 - pupilSideLength / 2
        let arcY = frame.height / 2 + pupilSideLength / 2
        let arcFrame = CGRectMake(arcX, arcY, pupilSideLength, pupilSideLength)
        let smile = CircleView(frame: arcFrame)
        smile.halfCircle = true
        smile.strokeWidth = Constants.EyepieceStrokeWidth / 2
        smile.backgroundColor = .clearColor()
        
        blurBackgroundView!.contentView.addSubview(smile)
    }
    private func randomEyeDirection() -> EyeDirection {
        return [EyeDirection.North,
            EyeDirection.NorthEast,
            EyeDirection.East,
            EyeDirection.SouthEast,
            EyeDirection.South,
            EyeDirection.SouthWest,
            EyeDirection.West,
            EyeDirection.NorthWest][Int(arc4random_uniform(8))]
    }
}
