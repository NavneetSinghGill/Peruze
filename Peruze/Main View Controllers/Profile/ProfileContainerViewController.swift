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
  var profileOwner: Person? {
    didSet {
      self.setChildViewControllerData()
    }
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tabBar.hidden = true
  }
  private func setChildViewControllerData() {
    print("Container View Child View Controllers")
    print(self.childViewControllers)
    for childVC in childViewControllers {
      switch childVC {
      case let uploadsVC as ProfileUploadsViewController:
        uploadsVC.dataSource.personRecordID = profileOwner?.valueForKey("recordIDName") as? String
        break
      case let favoritesVC as ProfileFavoritesViewController:
        //favoritesVC.dataSource.favorites = profileOwner!.favorites
        break
      case let reviewsVC as ProfileReviewsViewController:
        //reviewsVC.dataSource.reviews = profileOwner!.reviews
        break
      case let exchangesVC as ProfileExchangesViewController:
        //exchangesVC.dataSource.exchanges = profileOwner!.completedExchanges
        break
      default:
        //do nothing
        break
      }
    }
  }
}