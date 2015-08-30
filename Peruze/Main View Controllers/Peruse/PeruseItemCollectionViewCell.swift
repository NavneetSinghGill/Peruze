//
//  PeruseItemCollectionViewCell.swift
//  Peruse
//
//  Created by Phillip Trent on 6/2/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class PeruseItemCollectionViewCell: UICollectionViewCell, UITextViewDelegate, UIScrollViewDelegate {
  //TODO: There should only be a segue if the user lets go of the scroll view while content offset < 0
  private struct Constants {
    static let BufferSpace: CGFloat = 8
    static let FilledHeartName = "Heart_Filled"
    static let EmptyHeartName = "Heart_Outline"
    static let ExchangePrompt = "Make Offer!"
    static let DownArrowName = "Down_Arrow_Light"
    static let LargeHeartName = "Large_Heart"
  }
  
  //MARK: - Variables
  var item: NSManagedObject? { didSet { updateUI() } }
  var delegate: PeruseItemCollectionViewCellDelegate?
  
  @IBOutlet weak var mutualFriendsLabel: UILabel!
  @IBOutlet weak var ownerNameLabel: UILabel!
  @IBOutlet weak var ownerProfileImage: CircleImage!
  @IBOutlet weak var itemImageView: UIImageView!
  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.delegate = self
      scrollView.alwaysBounceVertical = true
    }
  }
  
  //Views
  private var itemNameLabel = UILabel()
  private var itemDescriptionTextView = UILabel()
  private var favoriteImageView = UIImageView()
  private var exchangeView = UIView()
  private var exchangeLabel = UILabel()
  private var exchangeArrow = UIImageView()
  private var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
  var itemFavorited = false {
    didSet {
      if itemFavorited {
        favoriteImageView.image = UIImage(named: Constants.FilledHeartName)
        heartFlash()
      } else {
        favoriteImageView.image = UIImage(named: Constants.EmptyHeartName)
      }
    }
  }
  
  //MARK: - Lifecycle
  override func awakeFromNib() {
    super.awakeFromNib()
    
    //add gesture recognizers
    let singleTap = UITapGestureRecognizer(target: self, action: "singleTap:")
    singleTap.numberOfTapsRequired = 1
    singleTap.enabled = true
    singleTap.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(singleTap)
    
    let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTap:")
    doubleTap.numberOfTapsRequired = 2
    doubleTap.enabled = true
    doubleTap.cancelsTouchesInView = false
    scrollView.addGestureRecognizer(doubleTap)
    
    setupViewProperties()
  }
  
  func setupViewProperties() {
    //setup view properties
    itemNameLabel.font = .preferredFontForTextStyle(UIFontTextStyleHeadline)
    itemNameLabel.numberOfLines = 0
    itemNameLabel.textAlignment = .Center
    itemDescriptionTextView.font = .preferredFontForTextStyle(UIFontTextStyleBody)
    itemDescriptionTextView.numberOfLines = 100
    itemDescriptionTextView.backgroundColor = UIColor.clearColor()
    exchangeView.backgroundColor = .blackColor()
    exchangeLabel.font = UIFont.systemFontOfSize(CGFloat(21))
    exchangeLabel.text = Constants.ExchangePrompt
    exchangeLabel.textColor = .whiteColor()
    exchangeLabel.textAlignment = .Center
    exchangeArrow.contentMode = .ScaleAspectFit
    exchangeArrow.image = UIImage(named: Constants.DownArrowName)
    favoriteImageView.contentMode = .ScaleAspectFit
  }
  
  override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    setupViewProperties()
    scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
    setupScrollView()
    updateUI()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    blurView.removeFromSuperview()
    itemDescriptionTextView.removeFromSuperview()
    itemNameLabel.removeFromSuperview()
    favoriteImageView.removeFromSuperview()
  }
  
  //MARK: - Gesture Handling
  func singleTap(sender: UITapGestureRecognizer) {
    //favorite buffer is 3x the size of the favorite button
    let bufferX = favoriteImageView.frame.origin.x - favoriteImageView.frame.width
    let bufferY = favoriteImageView.frame.origin.y - favoriteImageView.frame.height
    let bufferWidth = favoriteImageView.frame.width * 3
    let bufferHeight = favoriteImageView.frame.height * 3
    let favoriteBuffer = CGRectMake(bufferX, bufferY, bufferWidth, bufferHeight)
    if CGRectContainsPoint(favoriteBuffer, sender.locationInView(scrollView)) {
      itemFavorited = !itemFavorited
      delegate?.itemFavorited(item!, favorite: itemFavorited)
    } else if scrollView.contentOffset != CGPointMake(0, 0) {
      scrollView.scrollRectToVisible(CGRectMake(0, 0, 10, 10), animated: true)
    } else if CGRectContainsPoint(ownerProfileImage.frame, sender.locationInView(contentView)) {
      if
        let owner = item?.valueForKey("owner") as? NSManagedObject,
        let recordID = owner.valueForKey("recordIDName") as? String
      {
        delegate?.segueToProfile(recordID)
      }
    }
  }
  
  func doubleTap(sender: UITapGestureRecognizer) {
    itemFavorited = true
    delegate?.itemFavorited(item!, favorite: itemFavorited)
  }
  
  //MARK: - Drawing and UI
  
  private func updateUI() {
    if let imageData = item?.valueForKey("image") as? NSData {
      itemImageView.image = UIImage(data: imageData)
    } else {
      itemImageView.image = UIImage()
    }
    if let title = item?.valueForKey("title") as? String {
      itemNameLabel.text = title
    } else {
      itemNameLabel.text = "Error"
    }
    if let detail = item?.valueForKey("detail") as? String {
      itemDescriptionTextView.text = detail
    } else {
      itemDescriptionTextView.text = "Error"
    }
    if let owner = item?.valueForKey("owner") as? NSManagedObject {
      if let ownerName = owner.valueForKey("firstName") as? String {
        ownerNameLabel.text = ownerName
      } else {
        ownerNameLabel.text = "Error"
      }
      if let ownerImageData = owner.valueForKey("image") as? NSData {
        ownerProfileImage.image = UIImage(data: ownerImageData)
      } else {
        ownerProfileImage.image = UIImage()
      }
    }
    //      mutualFriendsLabel.hidden = (item.owner.mutualFriends == 0 || item.owner.mutualFriends == nil)
    //      mutualFriendsLabel.text = "\(item.owner.mutualFriends) mutual friends"
  }
  
  private func heartFlash() {
    let heart = UIImageView()
    heart.frame = ownerProfileImage.frame
    heart.frame.origin = CGPointMake(itemImageView.frame.origin.x + (itemImageView.frame.width / 2) - (heart.frame.width / 2), itemImageView.frame.origin.y + (itemImageView.frame.height / 2) - (heart.frame.height / 2))
    heart.contentMode = .ScaleAspectFit
    heart.image = UIImage(named: Constants.LargeHeartName)
    heart.alpha = 1
    insertSubview(heart, aboveSubview: scrollView)
    UIView.animateWithDuration(1, delay: 0, options: .CurveEaseIn, animations: {
      heart.alpha = 0
      }) { (_) -> Void in
        heart.removeFromSuperview()
    }
  }
  
  private func setupScrollView() {
    //define the height of the views already on screen
    let itemAndPersonHeight = ownerProfileImage.frame.size.height / 2 + itemImageView.frame.height
    itemImageViewNormalOriginY = itemImageView.frame.origin.y
    profilePicNormalOriginY = ownerProfileImage.frame.origin.y
    ownerNameNormalOriginY = ownerNameLabel.frame.origin.y
    mutualFriendsNormalOriginY = mutualFriendsLabel.frame.origin.y
    
    //get sizeToFit size for item detail view and item name label
    itemDescriptionTextView.frame = itemImageView.frame
    itemDescriptionTextView.sizeToFit()
    itemNameLabel.frame = frame
    itemNameLabel.sizeToFit()
    
    //check to make sure everything will be visible
    let minVisibleHeight = itemNameLabel.frame.height + Constants.BufferSpace * 2
    let viewIsTooSmall = frame.height - itemAndPersonHeight - Constants.BufferSpace < minVisibleHeight
    
    //set the content height
    let textViewHeight = itemDescriptionTextView.bounds.height + Constants.BufferSpace
    let scrollViewContentHeight = viewIsTooSmall ? frame.height + textViewHeight: itemAndPersonHeight + Constants.BufferSpace + itemNameLabel.frame.height + Constants.BufferSpace + textViewHeight
    scrollView.contentSize = CGSizeMake(frame.width, scrollViewContentHeight)
    
    setupNameAndDescription(viewIsTooSmall, visiblesHeight: itemAndPersonHeight)
    setupExchangeView(viewIsTooSmall)
    
  }
  
  private func setupNameAndDescription(small: Bool, visiblesHeight: CGFloat) {
    //setup description
    let descX = itemImageView.frame.origin.x
    let descY = small ? frame.height : visiblesHeight + Constants.BufferSpace * 2 + itemNameLabel.frame.height
    let descWidth = itemImageView.frame.width
    let descHeight = itemImageView.frame.height * 2 //random height for sizetofit
    itemDescriptionTextView.frame = CGRectMake(descX, descY, descWidth, descHeight)
    itemDescriptionTextView.sizeToFit()
    
    //setup item name label
    itemNameLabel.numberOfLines = 0
    let nameX = frame.width / 2 - itemNameLabel.frame.width / 2
    let nameY = itemDescriptionTextView.frame.minY - Constants.BufferSpace - itemNameLabel.frame.height
    let nameWidth = itemNameLabel.frame.width
    let nameHeight = itemNameLabel.frame.height
    itemNameLabel.frame = CGRectMake(nameX, nameY, nameWidth, nameHeight)
    if itemNameLabel.frame.maxX >= itemImageView.frame.maxX - ownerNameLabel.frame.height - Constants.BufferSpace {
      itemNameLabel.frame = CGRectMake(itemImageView.frame.minX, nameY, itemImageView.frame.width - Constants.BufferSpace - ownerNameLabel.frame.height, itemNameLabel.frame.height)
    }
    
    //setup favorite image
    let favoriteX = itemNameLabel.frame.origin.x + itemNameLabel.frame.width + Constants.BufferSpace
    let favoriteY = itemNameLabel.frame.origin.y
    let favoriteWidth = ownerNameLabel.frame.height
    favoriteImageView.frame = CGRectMake(favoriteX, favoriteY, favoriteWidth, favoriteWidth)
    
    //setup UIBlurView
    let blurX:CGFloat = 0
    let blurY = nameY - Constants.BufferSpace
    let blurWidth = scrollView.frame.width
    let blurHeight = scrollView.contentSize.height
    blurView.frame = CGRectMake(blurX, blurY, blurWidth, blurHeight)
    
    //add to the scrollView
    scrollView.addSubview(blurView)
    scrollView.addSubview(itemDescriptionTextView)
    scrollView.addSubview(itemNameLabel)
    scrollView.addSubview(favoriteImageView)
    
  }
  
  private func setupExchangeView(small: Bool) {
    //setup exchangeView
    let exchangeX = scrollView.frame.origin.x
    let exchangeY = scrollView.frame.origin.y - ownerProfileImage.frame.height
    let exchangeWidth = scrollView.frame.width
    let exchangeHeight = ownerProfileImage.frame.height
    exchangeView.frame = CGRectMake(exchangeX, exchangeY, exchangeWidth, exchangeHeight)
    
    //setup exchangeLabel
    exchangeLabel.frame = exchangeView.frame
    exchangeLabel.sizeToFit()
    exchangeLabel.center = exchangeView.center
    
    //setup exchangeArrow
    let arrowX = exchangeLabel.frame.origin.x
    let arrowY = exchangeLabel.frame.maxY
    let arrowWidth = exchangeLabel.frame.width
    let arrowHeight = exchangeView.frame.maxY - arrowY - Constants.BufferSpace
    exchangeArrow.frame = CGRectMake(arrowX, arrowY, arrowWidth, arrowHeight)
    
    scrollView.addSubview(exchangeView)
    scrollView.addSubview(exchangeLabel)
    scrollView.addSubview(exchangeArrow)
  }
  
  //MARK: - UIScrollViewDelegate
  
  private var itemImageViewNormalOriginY: CGFloat?
  private var profilePicNormalOriginY: CGFloat?
  private var ownerNameNormalOriginY: CGFloat?
  private var mutualFriendsNormalOriginY: CGFloat?
  private var segueShouldHappen = false
  private var segueHappened = false
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    if scrollView.contentOffset.y < 0 {
      
      //profile picture
      let newProfX = ownerProfileImage.frame.origin.x
      let newProfY = profilePicNormalOriginY! - scrollView.contentOffset.y
      let newProfWidth = ownerProfileImage.frame.width
      let newProfHeight = ownerProfileImage.frame.height
      ownerProfileImage.frame = CGRectMake(newProfX, newProfY, newProfWidth, newProfHeight)
      
      //owner name label
      let newNameX = ownerNameLabel.frame.origin.x
      let newNameY = ownerNameNormalOriginY! - scrollView.contentOffset.y
      let newNameWidth = ownerNameLabel.frame.width
      let newNameHeight = ownerNameLabel.frame.height
      ownerNameLabel.frame = CGRectMake(newNameX, newNameY, newNameWidth, newNameHeight)
      
      //mutual friends label
      let newMutualX = mutualFriendsLabel.frame.origin.x
      let newMutualY = mutualFriendsNormalOriginY! - scrollView.contentOffset.y
      let newMutualWidth = mutualFriendsLabel.frame.width
      let newMutualHeight = mutualFriendsLabel.frame.height
      mutualFriendsLabel.frame = CGRectMake(newMutualX, newMutualY, newMutualWidth, newMutualHeight)
      
      //item image
      let newImgX = itemImageView.frame.origin.x
      let newImgY = itemImageViewNormalOriginY! - scrollView.contentOffset.y
      let newImgWidth = itemImageView.frame.width
      let newImgHeight = itemImageView.frame.height
      itemImageView.frame = CGRectMake(newImgX, newImgY, newImgWidth, newImgHeight)
      
      if scrollView.contentOffset.y < -exchangeView.frame.height {
        exchangeView.backgroundColor = .greenColor()
        let pinnedFrame = CGRectMake(0, 0, exchangeView.frame.width, exchangeView.frame.height)
        exchangeView.frame = self.convertRect(pinnedFrame, toView: scrollView)
        exchangeLabel.frame = self.convertRect(pinnedFrame, toView: scrollView)
        segueShouldHappen = true
      } else {
        //setup exchangeView
        let exchangeX = scrollView.frame.origin.x
        let exchangeY = scrollView.frame.origin.y - ownerProfileImage.frame.height
        let exchangeWidth = scrollView.frame.width
        let exchangeHeight = ownerProfileImage.frame.height
        exchangeView.frame = CGRectMake(exchangeX, exchangeY, exchangeWidth, exchangeHeight)
        exchangeLabel.frame = exchangeView.frame
        exchangeView.backgroundColor = .blackColor()
      }
    } else {
      exchangeView.backgroundColor = .blackColor()
    }
  }
  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    if segueShouldHappen { delegate?.segueToExchange(item!) }
    segueShouldHappen = false
  }
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if scrollView.contentOffset.y >= -exchangeView.frame.height {
      if segueShouldHappen {
        segueShouldHappen = false
      }
      exchangeView.backgroundColor = .blackColor()
    }
  }
}

//MARK: - Item Cell Delegate
protocol PeruseItemCollectionViewCellDelegate {
  func itemFavorited(item: NSManagedObject, favorite: Bool)
  func segueToProfile(ownerID: String)
  func segueToExchange(item: NSManagedObject)
}
