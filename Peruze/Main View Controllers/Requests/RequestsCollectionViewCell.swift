//
//  RequestsCollectionViewCell.swift
//  Peruse
//
//  Created by Phillip Trent on 6/15/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class RequestsCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
  
  private struct Constants {
    static let BufferSize: CGFloat = 8
    struct Animation {
      static let Duration: NSTimeInterval = 0.5
      static let Delay: NSTimeInterval = 0
      
    }
  }
  
  //from Data Source
  //their item
  var exchange: Exchange? {
    didSet {
      itemOfferedToUser = exchange?.valueForKey("itemOffered") as? Item
      itemRequestedFromUser = exchange?.valueForKey("itemRequested") as? Item
    }
  }
  private var itemOfferedToUser: Item? {
    didSet {
      if
        let item = itemOfferedToUser,
        let owner = item.valueForKey("owner") as? NSManagedObject,
        let ownerImageData = owner.valueForKey("image") as? NSData,
        let itemImageData = item.valueForKey("image") as? NSData,
        let ownerName = owner.valueForKey("firstName") as? String,
        let itemTitle = item.valueForKey("title") as? String,
      let itemDescription = item.valueForKey("detail") as? String
      {
        profilePicture.image = UIImage(data: ownerImageData)
        profileName.text = ownerName
        theirItemImageView.image = UIImage(data: itemImageData)
        forTheirLabel.text = "for \(ownerName)'s"
        aboutTheirItemLabel.text = "About \(itemTitle)"
        theirItemNameLabel.text = itemTitle
        theirItemDescription.numberOfLines = 0
        theirItemDescription.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        theirItemDescription.text = itemDescription
        theirSquareItemImageView.contentMode =  UIViewContentMode.ScaleAspectFill
        theirSquareItemImageView.image = UIImage(data: itemImageData)
        setNeedsDisplay()
      }
    }
  }
  
  //your item
  private var itemRequestedFromUser: Item? {
    didSet {
      if let item = itemRequestedFromUser {
        if let imageData = item.valueForKey("image") as? NSData {
          yourItemImageView.image = UIImage(data: imageData)
        }
        yourItemNameLabel.text = item.valueForKey("title") as? String
        setNeedsDisplay()
        
      }
    }
  }
  
  //view controller delegate
  var delegate: RequestCollectionViewCellDelegate?
  
  //top center
  @IBOutlet weak var profilePicture: CircleImage!
  @IBOutlet weak var profileName: UILabel!
  @IBOutlet weak var wouldLikeToTradeLabel: UILabel!
  
  //middle left
  @IBOutlet weak var yourItemImageView: CircleImage!
  @IBOutlet weak var yourLabel: UILabel!
  @IBOutlet weak var yourItemNameLabel: UILabel!
  
  //middle center
  @IBOutlet weak var exchangeArrowImageView: UIImageView!
  
  //middle right
  @IBOutlet weak var theirItemImageView: CircleImage!
  @IBOutlet weak var forTheirLabel: UILabel!
  @IBOutlet weak var theirItemNameLabel: UILabel!
  
  //bottom left and right
  @IBOutlet weak var cancelRequestImageView: UIImageView!
  @IBOutlet weak var confirmRequestImageView: UIImageView!
  private var cancelCircleView: CircleView?
  private var confirmCircleView: CircleView?
  
  //bottom center
  @IBOutlet weak var aboutTheirItemLabel: UILabel!
  @IBOutlet weak var downArrowImageView: UIImageView!
  
  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.delegate = self
      scrollView.pagingEnabled = true
    }
  }
  
  //below the screen
  private var theirItemDescription = UILabel()
  private var theirSquareItemImageView = UIImageView()
  
  override func awakeFromNib() {
    originalConfirmFrame = confirmRequestImageView.frame
    let tap = UITapGestureRecognizer(target: self, action: "tap:")
    scrollView.addGestureRecognizer(tap)
    
    cancelCircleView = CircleView()
    cancelCircleView!.strokeColor = .redColor()
    cancelCircleView!.backgroundColor = .clearColor()
    
    confirmCircleView = CircleView()
    confirmCircleView!.strokeColor = .greenColor()
    confirmCircleView!.backgroundColor = .clearColor()
    
    insertSubview(cancelCircleView!, atIndex: 0)
    insertSubview(confirmCircleView!, atIndex: 0)
  }
  
  func tap(sender: UITapGestureRecognizer) {
    
    //view in center of screen
    let view = CircleView(frame: CGRectMake(0, 0, scrollView.frame.width, scrollView.frame.width))
    view.center = exchangeArrowImageView.center
    view.frame.inset(dx: view.frame.width / 4, dy: view.frame.width / 4)
    view.backgroundColor = .clearColor()
    
    //overlay for square image view
    let largeImage = UIImageView(frame: theirSquareItemImageView.frame)
    
    if confirmCircleView!.frame.contains(sender.locationInView(self)) {
      view.strokeColor = .greenColor()
      largeImage.image = UIImage(named: "Large_Check_Mark")
      exchangeArrowImageView.image = UIImage(named: "Check_Mark")
      
      addSubview(view)
      scrollView.addSubview(largeImage)
      UIView.animateWithDuration(Constants.Animation.Duration,
        delay: Constants.Animation.Delay,
        options: .CurveEaseOut,
        animations: {
          view.alpha = 0.0
          largeImage.alpha = 0.0
        }, completion: {(_) -> Void in
          view.removeFromSuperview()
          largeImage.removeFromSuperview()
          self.delegate?.requestAccepted(self.exchange!)
      })
    } else if cancelCircleView!.frame.contains(sender.locationInView(self)) {
      view.strokeColor = .redColor()
      exchangeArrowImageView.image = UIImage(named: "X")
      largeImage.image = UIImage(named: "Large_X")
      
      addSubview(view)
      scrollView.addSubview(largeImage)
      UIView.animateWithDuration(Constants.Animation.Duration,
        delay: Constants.Animation.Delay,
        options: .CurveLinear ,
        animations: {
          view.alpha = 0.0
          largeImage.alpha = 0.0
        }, completion: {(_) -> Void in
          view.removeFromSuperview()
          largeImage.removeFromSuperview()
          self.delegate?.requestDenied(self.exchange!)
      })
    }
  }
  
  override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    if 2 * cancelCircleView!.frame.width != 3 * cancelRequestImageView.frame.width {
      cancelCircleView!.frame = cancelRequestImageView.frame
      confirmCircleView!.frame = confirmRequestImageView.frame
      let width: CGFloat = 2 * cancelCircleView!.frame.width / 3
      let height: CGFloat = 2 * cancelCircleView!.frame.height / 3
      centerFrameWithNewSize(&cancelRequestImageView!.frame, size: CGSizeMake(width, height))
      centerFrameWithNewSize(&confirmRequestImageView!.frame, size: CGSizeMake(width, height))
    }
    
    let squareItemImageWidth = frame.width - 2 * Constants.BufferSize
    theirSquareItemImageView.frame.size = CGSizeMake(squareItemImageWidth, squareItemImageWidth)
    theirSquareItemImageView.frame.origin = CGPointMake(Constants.BufferSize, 0)
    updateFrame(&theirSquareItemImageView.frame, yDelta: frame.maxY + Constants.BufferSize + (frame.height * 1/12))
    
    theirItemDescription.frame = CGRectMake(0, 0, frame.width - 2 * Constants.BufferSize, frame.height * 2)
    theirItemDescription.sizeToFit()
    theirItemDescription.frame.size = CGSizeMake(frame.width - 2 * Constants.BufferSize, theirItemDescription.frame.height)
    theirItemDescription.frame.origin = CGPointMake(Constants.BufferSize, 0)
    updateFrame(&theirItemDescription.frame, yDelta: theirSquareItemImageView.frame.maxY + Constants.BufferSize)
    
    scrollView.contentSize = CGSizeMake(frame.width, frame.height * 2 > theirItemDescription.frame.maxY ? frame.height * 2 : theirItemDescription.frame.maxY)
    scrollView.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated: false)
    
    scrollView.addSubview(theirItemDescription)
    scrollView.addSubview(theirSquareItemImageView)
  }
  
  var originalConfirmFrame: CGRect?
  var lastOffsetY: CGFloat = 0
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let offsetDelta = lastOffsetY - scrollView.contentOffset.y
    lastOffsetY = scrollView.contentOffset.y
    
    updateFrame(&profilePicture.frame, yDelta: offsetDelta)
    updateFrame(&profileName.frame, yDelta: offsetDelta)
    updateFrame(&wouldLikeToTradeLabel.frame, yDelta: offsetDelta)
    
    updateFrame(&yourItemImageView.frame, yDelta: offsetDelta)
    updateFrame(&yourLabel.frame, yDelta: offsetDelta)
    updateFrame(&yourItemNameLabel.frame, yDelta: offsetDelta)
    
    updateFrame(&exchangeArrowImageView.frame, yDelta: offsetDelta)
    
    updateFrame(&theirItemImageView.frame, yDelta: offsetDelta)
    updateFrame(&forTheirLabel.frame, yDelta: offsetDelta)
    updateFrame(&theirItemNameLabel.frame, yDelta: offsetDelta)
    
    let denominator:CGFloat = 1.5
    updateFrame(&cancelRequestImageView.frame, yDelta: offsetDelta / denominator)
    updateFrame(&cancelCircleView!.frame, yDelta: offsetDelta / denominator)
    updateFrame(&confirmRequestImageView.frame, yDelta: offsetDelta / denominator)
    updateFrame(&confirmCircleView!.frame, yDelta: offsetDelta / denominator)
    
    
    updateFrame(&aboutTheirItemLabel.frame, yDelta: offsetDelta)
    updateFrame(&downArrowImageView.frame, yDelta: offsetDelta)
  }
  
  private func updateFrame(inout frame: CGRect, yDelta: CGFloat) {
    frame = frame.newFrameWithYChangedBy(yDelta)
  }
  private func centerFrameWithNewSize(inout frame: CGRect, size: CGSize) {
    let center = CGPointMake(frame.origin.x + frame.width / 2, frame.origin.y + frame.height / 2)
    frame = frame.copyFrameWithNewSize(size)
    frame.origin = CGPointMake(center.x - size.width / 2, center.y - size.height / 2)
  }
}
//MARK: - Convenience CGRect Extension
extension CGRect {
  func copyFrameWithNewY(newY: CGFloat) -> CGRect {
    return CGRectMake(origin.x, newY, width, height)
  }
  func newFrameWithYChangedBy(amount: CGFloat) -> CGRect {
    return CGRectMake(origin.x, origin.y + amount, width, height)
  }
  func copyFrameWithNewSize(size: CGSize) -> CGRect {
    return CGRectMake(origin.x, origin.y, size.width, size.height)
  }
}
//MARK: - Request Cell Delegate
protocol RequestCollectionViewCellDelegate {
  func requestAccepted(request: Exchange)
  func requestDenied(request: Exchange)
}
