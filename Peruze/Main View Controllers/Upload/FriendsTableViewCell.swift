//
//  FriendsTableViewCell.swift
//  Peruze
//
//  Created by stplmacmini11 on 01/12/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImageView: CircleImage!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    var friendDataDict: NSDictionary!
    var inviteTapBlock = {}
    @IBAction func inviteButtonTapped(sender: UIButton!) {
        self.inviteTapBlock()
    }
}
