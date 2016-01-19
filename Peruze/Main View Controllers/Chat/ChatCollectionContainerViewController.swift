//
//  ChatCollectionContainerViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 19/01/16.
//  Copyright © 2016 Peruze, LLC. All rights reserved.
//

import UIKit

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
        self.theirItemNameLabel.text = self.theirItemName
        self.yourItemNameLabel.text = self.yourItemName
        self.itemImage.itemImagesTappable = (prominentImage!.image!, lesserImage!.image!, prominentImageTapBlock: {
            self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemOffered") as! NSManagedObject)
            }, lesserImageTapBlock: {
                self.showChatItemDelegate.showItem(self.exchange.valueForKey("itemRequested") as! NSManagedObject)
        })
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "viewTapped:")
        self.view.addGestureRecognizer(tapGesture)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
        self.view.endEditing(true)
    }
}
