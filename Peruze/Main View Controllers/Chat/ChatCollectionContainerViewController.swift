//
//  ChatCollectionContainerViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 19/01/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import UIKit
import SwiftLog

class ChatCollectionContainerViewController: UIViewController {
    
    @IBOutlet weak var itemImage: DoubleCircleImage!
    @IBOutlet weak var theirItemNameLabel: UILabel!
    @IBOutlet weak var yourItemNameLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var containerView: UIView!
    var theirItemName: String!
    var yourItemName: String!
    var prominentImage: CircleImage?
    var lesserImage: CircleImage?
    
    var exchange: NSManagedObject!
    var senderId: String!
    var senderDisplayName: String!
    var delegate: ChatDeletionDelegate?
    var showChatItemDelegate: showChatItemDetailDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.theirItemNameLabel.text = self.theirItemName
        self.yourItemNameLabel.text = self.yourItemName
        self.itemImage.itemImagesTappable = (prominentImage!.image!, lesserImage!.image!, prominentImageTapBlock: {
            self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemOffered") as! NSManagedObject)
            }, lesserImageTapBlock: {
                self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemRequested") as! NSManagedObject)
        })
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "viewTapped:")
        self.view.addGestureRecognizer(tapGesture)
        
//        let leftBarButton = UIBarButtonItem(image: self.itemImage.prominentImage?.image, style: .Plain, target: self, action: nil)
        let backBarButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backButtonTapped")
        
        let prominentButton = UIButton(frame: CGRectMake(0, 4, 34, 34))
        prominentButton.sd_setImageWithURL(NSURL(string: s3Url(self.exchange.valueForKey("itemOffered")!.valueForKey("imageUrl") as! String)), forState: UIControlState.Normal)
        prominentButton.layer.cornerRadius = prominentButton.frame.size.width / 2
        prominentButton.layer.masksToBounds = true
        prominentButton.addTarget(self, action: "showItemOffered", forControlEvents: UIControlEvents.TouchUpInside)
        let leftButton = UIBarButtonItem(customView: prominentButton)
        
        let lesserButton = UIButton(frame: CGRectMake(0, 4, 34, 34))
        lesserButton.sd_setImageWithURL(NSURL(string: s3Url(self.exchange.valueForKey("itemRequested")!.valueForKey("imageUrl") as! String)), forState: UIControlState.Normal)
        lesserButton.layer.cornerRadius = lesserButton.frame.size.width / 2
        lesserButton.layer.masksToBounds = true
        lesserButton.addTarget(self, action: "showItemRequested", forControlEvents: UIControlEvents.TouchUpInside)
        let rightButton = UIBarButtonItem(customView: lesserButton)
        
        self.navigationItem.setLeftBarButtonItems([backBarButton, leftButton], animated: true)
        self.navigationItem.setRightBarButtonItems([rightButton], animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let context = NSManagedObjectContext.MR_context()
        let ex = Exchange.MR_findFirstByAttribute("recordIDName", withValue: self.exchange.valueForKey("recordIDName") as! String, inContext: context)
        ex.setValue(true, forKey: "isRead")
        context.MR_saveToPersistentStoreAndWait()
    }
    
    func backButtonTapped() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func showItemOffered() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemOffered") as! NSManagedObject)
    }
    
    func showItemRequested() {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemRequested") as! NSManagedObject)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
        if (segue.identifier == "jsq") {
            if let chatCollectionVC = segue.destinationViewController as? ChatCollectionViewController {
                chatCollectionVC.exchange = self.exchange
                chatCollectionVC.senderId = self.senderId
                chatCollectionVC.senderDisplayName = self.senderDisplayName
                chatCollectionVC.delegate = self.delegate
            }
        }
    }
    
    func viewTapped(gesture: UIGestureRecognizer) {
        logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__)")
//        self.view.endEditing(true)
    }
}
