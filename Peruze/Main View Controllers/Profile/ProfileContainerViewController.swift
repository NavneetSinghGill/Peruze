//
//  ProfileContainerViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileContainerViewController: UITabBarController {
    var viewControllerNumber: Int? {
        didSet {
            if viewControllerNumber != nil {
                selectedIndex = viewControllerNumber!
            }
        }
    }
    var profileOwner: Person?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.hidden = true
    }
}