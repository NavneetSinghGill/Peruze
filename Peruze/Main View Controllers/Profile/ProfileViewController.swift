//
//  ProfileViewController.swift
//  Peruse, LLC
//
//  Created by Phillip Trent on 6/27/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import CloudKit
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
    
    
    
    numberOfExchangesLabel.text = "0"
    numberOfFavoritesLabel.text = "0"
    numberOfUploadsLabel.text = "0"
    
    
    //check for a person, if there's no person, then it's my profile
    if personForProfile == nil {
      personForProfile = Person.MR_findFirstByAttribute("me", withValue: true)
    }
    //setup the known information about the person
    if (personForProfile?.valueForKey("image") as? NSData != nil) {
        profileImageView.image = UIImage(data: personForProfile!.valueForKey("image") as! NSData)
        profileNameLabel.text = (personForProfile!.valueForKey("firstName") as! String)
    }
    //TODO: set #ofStars
    
    //Fetch user all info if not fetched
    if checkForUserInfo() == true {
        UIView.animateWithDuration(0.5, animations: { self.containerView.alpha = 1.0 }, completion: { (success) -> Void in
            self.updateChildViewControllers()
        })
        self.updateViewAfterGettingResponse()
    }
    
    if tabBarController == nil {
      let done = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done:")
      done.tintColor = UIColor.redColor()
      navigationItem.rightBarButtonItem = done
    }
    uploadsButton.imageView!.image = UIImage(named: Constants.Images.UploadsFilled)
    reviewsButton.imageView!.image = UIImage(named: Constants.Images.Reviews)
    favoritesButton.imageView!.image = UIImage(named: Constants.Images.Favorites)
    exchangesButton.imageView!.image = UIImage(named: Constants.Images.Exchanges)
    starView.backgroundColor = .clearColor()
    starView.numberOfStars = 0
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "profileUpdate:", name: "profileUpdate", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetchUserProfileIfNeeded", name: "FetchUserProfileIfNeeded", object: nil)
  }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updateViewAfterGettingResponse()
    }
    
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerSpinner.frame = containerView.frame
  }
    func profileUpdate(noti:NSNotification){
        let me = Person.MR_findFirstByAttribute("me", withValue: true, inContext: managedConcurrentObjectContext)
        let userInfo:NSDictionary = noti.userInfo!
        let updatedProfileImage = (userInfo.valueForKey("circleImage") as? CircleImage)!
        let imageData = UIImagePNGRepresentation(updatedProfileImage.image!)
        me!.setValue(imageData, forKey: "image")
        managedConcurrentObjectContext.MR_saveToPersistentStoreAndWait()
        let op = PostUserOperation(presentationContext: self, database: CKContainer.defaultContainer().publicCloudDatabase, context: managedConcurrentObjectContext)
        OperationQueue().addOperation(op)
        dispatch_async(dispatch_get_main_queue()) {
            self.profileImageView.image = UIImage(data: me!.valueForKey("image") as! NSData)
        }
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
    
    func updateViewAfterGettingResponse() {
        numberOfExchangesLabel.text = String(self.personForProfile!.exchanges!.count)
        numberOfFavoritesLabel.text = String(self.personForProfile!.favorites!.count)
        numberOfUploadsLabel.text = String(Int(self.personForProfile!.uploads!.count))
    }
    
    func getAllDataOfCurentUser() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(false, forKey: "keyFetchedUserProfile")
        defaults.synchronize()
        
        //hide the container view and start loading data
        containerView.alpha = 0.0
        containerSpinner.startAnimating()
        view.addSubview(containerSpinner)
        
        //get the updated information for the profile
        let personForProfileRecordID = personForProfile?.valueForKey("recordIDName") as! String
        let completePersonRecordID = CKRecordID(recordName: personForProfile?.valueForKey("recordIDName") as! String)
        let completePerson = GetFullProfileOperation(
            personRecordID: completePersonRecordID,
            context: managedConcurrentObjectContext,
            database: CKContainer.defaultContainer().publicCloudDatabase,
            completionHandler: {
                print("\(NSDate())\nFinished GetFullProfileOperation")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let completeProfile = Person.MR_findFirstByAttribute("recordIDName", withValue: personForProfileRecordID)
                    self.personForProfile = completeProfile
                    self.containerSpinner.stopAnimating()
                    UIView.animateWithDuration(0.5, animations: { self.containerView.alpha = 1.0 }, completion: { (success) -> Void in
                        self.updateChildViewControllers()
                    })
                    self.updateViewAfterGettingResponse()
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setBool(true, forKey: "keyFetchedUserProfile")
                    defaults.synchronize()
                })
        })
        OperationQueue().addOperation(completePerson)
    }
    
    func checkForUserInfo() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let shouldFetchAllInfo = defaults.boolForKey("keyFetchedUserProfile")
        if shouldFetchAllInfo == false {
            getAllDataOfCurentUser()
        }
        return shouldFetchAllInfo
    }
    
    
    //MARK: - notification Obeserver method
    func fetchUserProfileIfNeeded() {
        checkForUserInfo()
    }
}
