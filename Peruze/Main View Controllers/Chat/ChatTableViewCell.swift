//
//  ChatTableViewCell.swift
//  Peruse
//
//  Created by Phillip Trent on 6/18/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    var data: Exchange? {
        didSet {
//            itemImage.itemImages = (data!.exchage.itemOffered.image, data!.exchage.itemRequested.image)
//            theirItemNameLabel.text = "\(data!.exchage.itemOffered.title)"
//            yourItemNameLabel.text = "for \(data!.exchage.itemRequested.title)"
//            let name = data!.messages.last!.senderDisplayName == data!.exchage.itemRequested.owner.firstName ? "you" : "\(data!.messages.last!.senderDisplayName)"
          //mostRecentTextString.text = name + ": \(data!.messages.last!.text)"
        }
    }
    @IBOutlet weak var itemImage: DoubleCircleImage!
    @IBOutlet weak var theirItemNameLabel: UILabel!
    @IBOutlet weak var yourItemNameLabel: UILabel!
    @IBOutlet weak var mostRecentTextString: UILabel!
}
