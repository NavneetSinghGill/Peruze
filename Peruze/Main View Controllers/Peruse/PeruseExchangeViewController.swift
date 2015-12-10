//
//  PeruseExchangeViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/9/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class PeruseExchangeViewController: UIViewController, UICollectionViewDelegate, UIGestureRecognizerDelegate {
  //MARK: - Constants
  private struct Constants {
    static let BufferSpace:CGFloat = 8
    static let MinimumLongPressDuration: NSTimeInterval = 0.10
    static let StrokeWidth: CGFloat = 2
    static let LongPressActionHandlerIdentifier: Selector = "handleLongPress:"
    static let UploadViewControllerIdentifier = "UploadViewController"
    struct NoItemAlert {
      static let title = "Come on!"
      static let cancelTitle = "Dismiss"
    }
    struct MoveCellAnimation {
      static let Duration: NSTimeInterval = 0.5
      static let SpringDamping: CGFloat = 0.5
      static let SpringVelocity: CGFloat = 0.5
    }
    struct MoveToRectAnimation {
      static let Duration: NSTimeInterval = 0.5
      static let SpringDamping: CGFloat = 0.5
      static let SpringVelocity: CGFloat = 0.5
    }
  }
  
  //MARK: - Variables
  var delegate: PeruseExchangeViewControllerDelegate?
  var itemSelectedForExchange: NSManagedObject!
  private var cellSize: CGSize?
  private var dataSource = PeruseExchangeItemDataSource()
  @IBOutlet weak var collectionView: UICollectionView! {
    didSet {
      dataSource.collectionView = collectionView
    }
  }
  @IBOutlet weak var topBlurView: UIVisualEffectView!
  @IBOutlet weak var bottomBlurView: UIVisualEffectView!
  @IBOutlet weak var checkmark: UIImageView!
  @IBOutlet weak var x: UIImageView!
  
  //your item
  @IBOutlet weak var leftCircleImageView: CircleImage!
  @IBOutlet weak var itemYoureExchangingLabel: UILabel!
  private var itemInCircleView: NSManagedObject? {
    didSet {
      if let imageData = itemInCircleView?.valueForKey("image") as? NSData,
        let title = itemInCircleView?.valueForKey("title") as? String {
          leftCircleImageView.image =  UIImage(data: imageData)
          itemYoureExchangingLabel.text = title
      }
    }
  }
  private let greenCircle = CircleView()
  //other person's item
  @IBOutlet weak var rightCircleImageView: CircleImage!
  @IBOutlet weak var otherPersonsFullNameLabel: UILabel!
  @IBOutlet weak var mutualFriendsLabel: UILabel!
  @IBOutlet weak var otherPersonsFirstNameLabel: UILabel!
  @IBOutlet weak var otherPersonsItemLabel: UILabel!
  @IBOutlet weak var otherPersonsProfileImageView: CircleImage!
  
  
  //MARK: - View Controller Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //setup collection view
    collectionView.delegate = self
    
    //setup gesture recognizers
    let longPress = UILongPressGestureRecognizer(target: self, action: Constants.LongPressActionHandlerIdentifier)
    longPress.delegate = self
    longPress.minimumPressDuration = Constants.MinimumLongPressDuration
    view.addGestureRecognizer(longPress)
    
    //setup left circle image and circle
    leftCircleImageView.image = nil
    itemYoureExchangingLabel.text = ""
    greenCircle.strokeWidth = Constants.StrokeWidth
    greenCircle.strokeColor = .blackColor()
    greenCircle.alpha = 1.0
    
    //setup item selected for exchange
    if let imageData = itemSelectedForExchange.valueForKey("image") as? NSData,
      let title = itemSelectedForExchange.valueForKey("title") as? String,
      let itemSelectedForExchangeOwner = itemSelectedForExchange.valueForKey("owner") as? NSManagedObject,
      let ownerName = itemSelectedForExchangeOwner.valueForKey("firstName") as? String,
      let ownerImageData = itemSelectedForExchangeOwner.valueForKey("image") as? NSData {
        
        //mutualFriendsLabel.text = "\(itemSelectedForExchange!.owner.mutualFriends) mutual friends"
        rightCircleImageView.image = UIImage(data: imageData)
        otherPersonsFullNameLabel.text = ownerName
        otherPersonsFirstNameLabel.text = "for \(ownerName)'s"
        otherPersonsItemLabel.text = title
        otherPersonsProfileImageView.image = UIImage(data: ownerImageData)
    }
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadCollectionViewManually", name: "reloadPeruzeExchangeScreen", object: nil)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let layout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
    
    //cell size
    let width = (collectionView.frame.width - 4.0 * Constants.BufferSpace) / 3.0
    cellSize = CGSizeMake(width, width + 2.0 * Constants.BufferSpace)
    layout.itemSize = cellSize!
    
    //insets for collection view cells and scroll view
    let insetTop = topBlurView.frame.maxY + Constants.BufferSpace
    let insetLeft = Constants.BufferSpace
    let insetBottom = bottomBlurView.frame.height + Constants.BufferSpace
    let insetRight = Constants.BufferSpace
    UIView.animateWithDuration(0.25) {
      layout.sectionInset = UIEdgeInsetsMake(insetTop, insetLeft, insetBottom, insetRight)
      self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(insetTop, insetLeft, insetBottom, insetRight)
    }
    
    //green circle view
    greenCircle.frame = leftCircleImageView.frame
    greenCircle.setNeedsDisplay()
    view.insertSubview(greenCircle, aboveSubview: leftCircleImageView)
  }
  
  //MARK: - Handling Segues
  @IBAction func closeTap(sender: UIButton) {
    exchangeCanceled()
  }
  @IBAction func checkTap(sender: UIButton) {
    exchangeCompleted()
  }
  
//  @IBAction func bottomBlurTap(sender: AnyObject) {
//    let bufferSize:CGFloat = 32
//    if sender.state == UIGestureRecognizerState.Ended {
//      if sender.locationInView(bottomBlurView).x >= checkmark.frame.minX - bufferSize {
//        exchangeCompleted()
//      } else if sender.locationInView(bottomBlurView).x <= x.frame.maxX + bufferSize {
//        exchangeCanceled()
//      }
//    }
//  }
  
  private func exchangeCompleted() {
    if !NetworkConnection.connectedToNetwork() {
      let alert = ErrorAlertFactory.alertForNetworkWithTryAgainBlock { self.exchangeCompleted() }
      presentViewController(alert, animated: true, completion: nil)
      return
    }
    if itemInCircleView == nil {
//      
//      let owner = itemSelectedForExchange.valueForKey("owner") as? NSManagedObject
//      
//      guard
//        let ownerName = owner?.valueForKey("firstName") as? String,
//        let itemTitle = itemSelectedForExchange.valueForKey("title") as? String else {
//          return
//      }
//      
//      let alert = UIAlertView(title: Constants.NoItemAlert.title,
//        message: "\(ownerName) is our really good friend! Surely you don't want to offer nothing in return for \(itemTitle).",
//        delegate: self,
//        cancelButtonTitle: Constants.NoItemAlert.cancelTitle)
//      alert.show()
        
        let alert = UIAlertController(title: "Peruze", message: "Select an item for exchange.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    } else {
      self.dismissViewControllerAnimated(true) {
        self.delegate?.itemChosenToExchange = self.itemInCircleView
      }
        
    }
  }
  
  private func exchangeCanceled() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  private func segueToUploadNewItem() {
    let UploadVC = storyboard!.instantiateViewControllerWithIdentifier(Constants.UploadViewControllerIdentifier) as! UploadViewController
    UploadVC.parentVC = self
    presentViewController(UploadVC, animated: true, completion: nil)
    //TODO: Implement this segue
  }
    
    func reloadCollectionViewManually() {
        dataSource.getItems()
        dataSource.collectionView!.reloadData()
    }
    
  //MARK: - Handling Long Press
  private struct PickedUpCell {
    var circleImage: CircleImage
    var indexPath: NSIndexPath
    var originalFrame: CGRect
    var item: NSManagedObject
  }
  
  //MARK: Variables
  private var pickedUpCell: PickedUpCell? {
    didSet {
      if let pickedUpCell = pickedUpCell,
        let imageData = pickedUpCell.item.valueForKey("image") as? NSData {
          pickedUpCell.circleImage.image = UIImage(data: imageData)
          pickedUpCell.circleImage.backgroundColor = .clearColor()
          view.addSubview(pickedUpCell.circleImage)
      }
    }
  }
  
  //MARK: Convenience Checks
  private func press(press: UILongPressGestureRecognizer, isOnView view: UIView) -> Bool {
    return CGRectContainsPoint(view.frame, press.locationInView(self.view))
  }
  
  private func pressIsInCollectionView(press: UILongPressGestureRecognizer) -> Bool {
    let loc = press.locationInView(view)
    return !CGRectContainsPoint(topBlurView.frame, loc) && !CGRectContainsPoint(bottomBlurView.frame, loc)
  }
  
  //MARK: Long Press Gesture Recognizer Target
  func handleLongPress(sender: UILongPressGestureRecognizer) {
    switch sender.state {
    case .Began:
      if press(sender, isOnView: leftCircleImageView) {
        cellPickedUpFromCircleView()
      } else if pressIsInCollectionView(sender) {
        cellPickedUpFromCollectionViewWithPress(sender)
      }
      break
    case .Changed:
      if pickedUpCell == nil { break }
      moveCellToLocation(sender.locationInView(view))
      if CGRectIntersectsRect(pickedUpCell!.circleImage.frame, leftCircleImageView.frame) {
        greenCircle.strokeColor = .greenColor()
        greenCircle.alpha = 1.0
      } else {
        if itemInCircleView != nil { greenCircle.alpha = 0.0 }
        greenCircle.strokeColor = .blackColor()
        
      }
      break
    default: //catches .Possible .Failed .Ended and .Cancelled
      if pickedUpCell == nil { break }
      if CGRectIntersectsRect(pickedUpCell!.circleImage.frame, leftCircleImageView.frame) {
        movePickedUpCellToCircleImage()
      } else {
        putPickedUpCellBackInCollectionView()
      }
      break
    }
  }
  
  //MARK: Cell Actions
  private func cellPickedUpFromCircleView() {
    if let currentCircleImage = leftCircleImageView,
      let yourItem = itemInCircleView {
        let newCircleImage = CircleImage(frame: currentCircleImage.frame.copyWithWidth(cellSize!.width, andHeight: cellSize!.width))
        newCircleImage.center = currentCircleImage.center
        pickedUpCell = PickedUpCell(circleImage: newCircleImage,
          indexPath: NSIndexPath(forItem: 0, inSection: 0),
          originalFrame: currentCircleImage.frame,
          item: yourItem)
        
        itemInCircleView = nil
        greenCircle.strokeColor = .greenColor()
        greenCircle.alpha = 1.0
        leftCircleImageView.image = nil
        itemYoureExchangingLabel.text = ""
    }
  }
  
  private func cellPickedUpFromCollectionViewWithPress(sender: UILongPressGestureRecognizer) {
    //get index path for cell to pick up
    let indexPath = collectionView.indexPathForItemAtPoint(sender.locationInView(collectionView))
    if indexPath != nil { cellPickedUpFromCollectionViewWithIndex(indexPath!) }
    
  }
  
  private func cellPickedUpFromCollectionViewWithIndex(indexPath: NSIndexPath) {
    //make check if cell is upload new item cell
    if indexPath.item == collectionView.numberOfItemsInSection(0) - 1 {
      segueToUploadNewItem()
      logw("Segue to upload item")
      return
    }
    
    //get cell at that index path
    let cellToPickUp = collectionView.cellForItemAtIndexPath(indexPath) as? PeruseExchangeItemCollectionViewCell
    if cellToPickUp == nil { return }
    
    let itemData = dataSource.deleteItemsAtIndexPaths([indexPath]).first
    if itemData == nil { assertionFailure("There is a cell at an index that doesn't have a backing item") }
    
    //set picked up cell
    let circleImageFrame = collectionView.convertRect(cellToPickUp!.frame, toView: view).copyWithHeight(cellToPickUp!.frame.width)
    self.pickedUpCell = PickedUpCell(circleImage: CircleImage(frame: circleImageFrame),
      indexPath: indexPath,
      originalFrame: circleImageFrame,
      item: itemData!)
    
    //animate and display things
    collectionView.deleteItemsAtIndexPaths([indexPath])
  }
  
  private func moveCellToLocation(location: CGPoint) {
    if pickedUpCell != nil {
      animateMovingCellToLocation(location)
    }
  }
  
  private func addCurrentCircleImageItemToCollectionView() {
    if let currentItem = itemInCircleView {
      //place the cell in the collection view
      let startIndexPath = NSIndexPath(forItem: 0, inSection: 0)
      dataSource.addItemsAtIndexPaths([currentItem], paths: [startIndexPath])
      collectionView.insertItemsAtIndexPaths([startIndexPath])
      let cellCreated = collectionView.cellForItemAtIndexPath(startIndexPath) as? PeruseExchangeItemCollectionViewCell
      
      //animate the move
      if let cell = cellCreated {
        let tempCircle = CircleImage(frame: leftCircleImageView.frame)
        tempCircle.image = leftCircleImageView.image
        view.insertSubview(tempCircle, belowSubview: greenCircle)
        animateMovingView(tempCircle,
          toRect: cell.convertRect(cell.imageView.frame, toView: view),
          withSpecialAnimations: {
            tempCircle.alpha = 0.0
            self.greenCircle.alpha = 0.0
          },
          andCompletion: {
            (_) -> Void in
            tempCircle.removeFromSuperview()
        })
      }
    }
    itemInCircleView = nil
  }
  
  private func movePickedUpCellToCircleImage() {
    if itemInCircleView != nil {
      addCurrentCircleImageItemToCollectionView()
    }
    if let cell = pickedUpCell {
      itemInCircleView = cell.item
      greenCircle.alpha = 0.0
      leftCircleImageView.alpha = 0.0
      itemYoureExchangingLabel.alpha = 0.0
      animateMovingView(cell.circleImage,
        toRect: leftCircleImageView.frame,
        withSpecialAnimations: { self.itemYoureExchangingLabel.alpha = 1.0 },
        andCompletion: { (_) -> Void in
          self.leftCircleImageView.alpha = 1.0
          cell.circleImage.removeFromSuperview()
      })
    }
    pickedUpCell = nil
  }
  
  private func putPickedUpCellBackInCollectionView() {
    if let cell = pickedUpCell {
      dataSource.addItemsAtIndexPaths([cell.item], paths: [cell.indexPath])
      collectionView.insertItemsAtIndexPaths([cell.indexPath])
      let cellCreated = collectionView.cellForItemAtIndexPath(cell.indexPath) as? PeruseExchangeItemCollectionViewCell
      
      let toRect = cellCreated != nil ? cellCreated!.convertRect(cellCreated!.imageView.frame, toView: view) : CGRectZero
      animateMovingView(cell.circleImage,
        toRect: toRect,
        withSpecialAnimations: {
          cell.circleImage.alpha = 0.0
          if self.itemInCircleView == nil {
            self.greenCircle.strokeColor = .blackColor()
            self.greenCircle.alpha = 1.0
          }
          self.itemYoureExchangingLabel.alpha = 1.0
        },
        andCompletion: { (_) -> Void in
          cell.circleImage.removeFromSuperview()
      })
      
    }
    pickedUpCell = nil
  }
  
  //MARK: Animations
  private func animateMovingCellToLocation(location: CGPoint) {
    UIView.animateWithDuration(Constants.MoveCellAnimation.Duration,
      delay: 0,
      usingSpringWithDamping: Constants.MoveCellAnimation.SpringDamping,
      initialSpringVelocity: Constants.MoveCellAnimation.SpringVelocity,
      options: .CurveEaseOut,
      animations: {
        self.pickedUpCell!.circleImage.center = location
      },
      completion: nil)
  }
  
  private func animateMovingView(view: UIView, toRect rect: CGRect, withSpecialAnimations animations: (() -> Void)?, andCompletion completion: ((Bool) -> Void)?) {
    UIView.animateWithDuration(Constants.MoveToRectAnimation.Duration,
      delay: 0,
      usingSpringWithDamping: Constants.MoveToRectAnimation.SpringDamping,
      initialSpringVelocity: Constants.MoveToRectAnimation.SpringVelocity,
      options: .CurveEaseOut,
      animations: {
        view.frame = rect
        if animations != nil { animations!() }
        view.setNeedsDisplay()
      }, completion: completion)
  }
  
  //MARK: Information Handling
  private func setupLeftViewWithItemInfo(item: Item?) {
    if let item = item {
      leftCircleImageView.image = UIImage(data: item.valueForKey("image") as! NSData)
      itemYoureExchangingLabel.text = item.valueForKey("title") as? String
      UIView.animateWithDuration(0.3, animations: { () -> Void in
        self.itemYoureExchangingLabel.alpha = 1.0
      })
    } else {
      UIView.animateWithDuration(0.3, animations: { () -> Void in
        self.leftCircleImageView.alpha = 0.0
        self.itemYoureExchangingLabel.alpha = 0.0
      })
    }
  }
  
  //MARK: - Collection View Delegate Methods
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    cellPickedUpFromCollectionViewWithIndex(indexPath)
    movePickedUpCellToCircleImage()
  }
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    //if the touch's location is above the bottom blur view, it should be recognized.
    let touchY = touch.locationInView(view).y
    let highestAcceptableY = bottomBlurView.frame.origin.y
    return touchY <= highestAcceptableY
  }
}

//MARK: - Convenience Methods for CGRect
private extension CGRect {
  func copy() -> CGRect{
    return CGRectMake(origin.x, origin.y, width, height)
  }
  func copyWithWidth(width: CGFloat) -> CGRect {
    return CGRectMake(origin.x, origin.y, width, height)
  }
  func copyWithHeight(height: CGFloat) -> CGRect {
    return CGRectMake(origin.x, origin.y, width, height)
  }
  func copyWithWidth(width: CGFloat, andHeight height:CGFloat) -> CGRect {
    return CGRectMake(origin.x, origin.y, width, height)
  }
  func copyWithSize(size: CGSize) -> CGRect {
    return CGRectMake(origin.x, origin.y, size.width, size.height)
  }
}

//MARK: - PeruseExchangeViewControllerDelegate
protocol PeruseExchangeViewControllerDelegate {
  var itemChosenToExchange: NSManagedObject? {get set}
}

