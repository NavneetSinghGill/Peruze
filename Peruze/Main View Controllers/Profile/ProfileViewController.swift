//
//  ProfileViewController.swift
//  Peruse, LLC
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
  
  private struct Constants {
    struct ViewControllerIndexes {
      static let Uploads = 0
      static let Reviews = 1
      static let Favorites = 2
      static let Exchanges = 3
    }
    struct SegueIdentifiers {
      static let Upload = "toUpload"
      static let Favorite = "toFavorite"
    }
    struct Images {
      static let Uploads = "Profile_Upload"
      static let UploadsFilled = "Profile_Upload_Filled"
      static let Reviews = "Profile_Star"
      static let ReviewsFilled = "Profile_Star_Filled"
      static let Favorites = "Profile_Heart"
      static let FavoritesFilled = "Profile_Heart_Filled"
      static let Exchanges = "Profile_Exchange"
      static let ExchangesFilled = "Profile_Exchange_Filled"
    }
  }
  
  //MARK: - Variables
  var personForProfile: Person?
  @IBOutlet weak var profileImageView: CircleImage!
  @IBOutlet weak var profileNameLabel: UILabel!
  @IBOutlet weak var numberOfExchangesLabel: UILabel!
  @IBOutlet weak var numberOfFavoritesLabel: UILabel!
  @IBOutlet weak var numberOfUploadsLabel: UILabel!
  @IBOutlet weak var uploadsButton: UIButton!
  @IBOutlet weak var reviewsButton: UIButton!
  @IBOutlet weak var favoritesButton: UIButton!
  @IBOutlet weak var exchangesButton: UIButton!
  @IBOutlet weak var starView: StarView!
  @IBOutlet weak var containerView: UIView!
  private let containerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
  
  //MARK: - UIViewController Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //hide the container view and start loading data
    containerView.alpha = 0.0
    containerSpinner.startAnimating()
    view.addSubview(containerSpinner)
    
    //check for a person, if there's no person, then it's my profile
    if personForProfile == nil {
      personForProfile = Model.sharedInstance().myProfile
    }
    //setup the known information about the person
    profileImageView.image = UIImage(data: personForProfile!.image!)
    profileNameLabel.text = "\(personForProfile!.firstName) \(personForProfile!.lastName)"
    //TODO: set #ofStars
    
    //get the updated information for the profile
    Model.sharedInstance().completePerson(personForProfile!, completion: { (completeProfile, error) -> Void in
      if error != nil {
        let alert = ErrorAlertFactory.alertFromError(error!, dismissCompletion: nil)
        self.presentViewController(alert, animated: true, completion: nil)
        return
      } else {
        self.personForProfile = completeProfile
        self.containerSpinner.stopAnimating()
        UIView.animateWithDuration(0.5, animations: { self.containerView.alpha = 1.0 }, completion: { (_) -> Void in
          self.updateChildViewControllers()
        })
      }
    })

    if tabBarController == nil {
      let done = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done:")
      done.tintColor = .redColor()
      navigationItem.rightBarButtonItem = done
    }
    
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
    starView.backgroundColor = .clearColor()
    starView.numberOfStars = 0
  }
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerSpinner.frame = containerView.frame
  }
  
  //MARK: - Handling Tab Segues
  @IBAction func uploadsTapped(sender: AnyObject) {
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
    for viewController in childViewControllers {
      if let vc = viewController as? ProfileContainerViewController {
        vc.viewControllerNumber = Constants.ViewControllerIndexes.Uploads
      }
    }
  }
  @IBAction func reviewsTapped(sender: AnyObject) {
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.ReviewsFilled)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
    for viewController in childViewControllers {
      if let vc = viewController as? ProfileContainerViewController {
        vc.viewControllerNumber = Constants.ViewControllerIndexes.Reviews
      }
    }
  }
  @IBAction func favoritesTapped(sender: AnyObject) {
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.FavoritesFilled)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
    for viewController in childViewControllers {
      if let vc = viewController as? ProfileContainerViewController {
        vc.viewControllerNumber = Constants.ViewControllerIndexes.Favorites
      }
    }
  }
  @IBAction func exchangesTapped(sender: AnyObject) {
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.Uploads)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.ExchangesFilled)
    for viewController in childViewControllers {
      if let vc = viewController as? ProfileContainerViewController {
        vc.viewControllerNumber = Constants.ViewControllerIndexes.Exchanges
      }
    }
  }
  
  func done(sender: UIBarButtonItem) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  //MARK: - Setting Info for Child View Controllers
  private func updateChildViewControllers() {
    print(self.childViewControllers)
    for childVC in childViewControllers {
      if let container = childVC as? ProfileContainerViewController {
        container.profileOwner = personForProfile
      }
    }
  }
}
