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
    @IBOutlet weak var nameLabel: UILabel!
    var friendDataDict: NSDictionary!
}
