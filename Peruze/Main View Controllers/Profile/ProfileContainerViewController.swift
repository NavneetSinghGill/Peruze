//
//  ProfileContainerViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import SwiftLog

class ProfileContainerViewController: UITabBarController {
  var viewControllerNumber: Int? {
    didSet {
      if viewControllerNumber != nil {
        selectedIndex = viewControllerNumber!
      }
    }
  }
  var profileOwner: Person? {
    didSet {
      self.setChildViewControllerData()
    }
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tabBar.hidden = true
    self.setChildViewControllerData()
  }
  private func setChildViewControllerData() {
    logw("Container VC With Person:")
    logw("\(profileOwner)")
    for childVC in childViewControllers {
      switch childVC {
      case let uploadsVC as ProfileUploadsViewController:
        uploadsVC.dataSource.personRecordID = profileOwner?.valueForKey("recordIDName") as? String
        break
      case let favoritesVC as ProfileFavoritesViewController:
        favoritesVC.dataSource.refresh()
        //favoritesVC.dataSource.favorites = profileOwner!.favorites
        break
      case let reviewsVC as ProfileReviewsViewController:
//        reviewsVC.dataSource.reviews = profileOwner!.reviews
        reviewsVC.dataSource.profileOwner = profileOwner
        break
      case let exchangesVC as ProfileExchangesViewController:
        //exchangesVC.dataSource.exchanges = profileOwner!.completedExchanges
        break
      case let mutualFriendsVC as  ProfileFriendsViewController:
        mutualFriendsVC.dataSource.profileOwner = profileOwner
        _ = mutualFriendsVC.view
        break
      default:
        //do nothing
        break
      }
    }
  }
}