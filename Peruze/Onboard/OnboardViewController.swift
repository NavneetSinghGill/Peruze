//
//  OnboardViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 5/23/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class OnboardViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, FBSDKLoginButtonDelegate {
    
    private struct Constants {
        static let PeruseWithoutWordsImageName = "Peruze_Launch_Image"
        static let PeruseWithWordsImageName = "Peruze_Start_Image"
        
        static let PageVCIdentifier = "OnboardPageViewController"
        static let PageItemVCIdentifier = "OnboardPageItemViewController"
        static let ProfileSetupSegueIdentifier = "showSelectProfilePhoto"
        
        static let FacebookPermissions = ["public_profile","user_photos"]
        
        static let contentImages: [String?] = ["Onboard_Upload_Cloud", nil, nil];
        static let movies: [String?] = [nil, "Onboard_Peruse", "Onboard_Exchange"]
        
        static let titles = ["Upload", "Peruze", "Exchange"]
        static let captions = ["upload what you have",
            "see what your network is offering",
            "make your best offer—you’ve only got one shot!"]
        static let AppDidBecomeActiveNotificationName = "applicationDidBecomeActive"
        struct Alert {
            static let NoPhotosTitle = "Can't Access Photos"
            static let NoPhotosMessage = "To keep everyone safe on Peruze, we need to know who you are, which means that we have to have a picture of you. Plus, who wouldn't want to see your shining face!"
        }
    }
    
    // MARK: - Variables
    @IBOutlet weak var scrollView: UIScrollView!
    private var imageView = UIImageView()
    private var pageViewController: UIPageViewController?
    private var facebookLoginButton: FBSDKLoginButton?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive", name: Constants.AppDidBecomeActiveNotificationName, object: nil)
        super.viewDidLoad()
        createPageViewController()
        setupPageControl()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.userInteractionEnabled = false
        setupScrollView()
        setupImages(view.frame.size)
        setupFacebookLoginButton()
        facebookLoginButton!.alpha = 0.0
        facebookLoginButton!.enabled = false
        
        //setup view to shrink
        let whiteView = UIView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        whiteView.backgroundColor = .whiteColor()
        view.insertSubview(whiteView, aboveSubview: scrollView)
        
        //setup base image
        let initialImageView = UIImageView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
        initialImageView.contentMode = .ScaleAspectFit
        initialImageView.backgroundColor = .clearColor()
        initialImageView.image = UIImage(named: Constants.PeruseWithoutWordsImageName)
        view.insertSubview(initialImageView, aboveSubview: whiteView)
        
        //animate
        UIView.animateWithDuration(3.0, animations: {
            whiteView.frame = CGRectMake(self.view.frame.maxX, 0, 0, self.view.frame.height)
            }) { (_) -> Void in
                UIView.animateWithDuration(1.5) {
                    self.facebookLoginButton!.alpha = 1.0
                }
                whiteView.removeFromSuperview()
                initialImageView.removeFromSuperview()
                self.facebookLoginButton!.enabled = true
                self.scrollView.userInteractionEnabled = true
        }
    }
    
    //MARK: - Gesture Recognizer
    @IBAction func tap(sender: UITapGestureRecognizer) {
        let bottomOfScrollView = CGRectMake(0, view.frame.height, view.frame.width, view.frame.height)
        scrollView.scrollRectToVisible(bottomOfScrollView, animated: true)
    }
    
    // MARK: - Setup
    private func setupScrollView() {
        let screenSizeWithDoubleHeight = CGSizeMake(self.view.bounds.width, self.view.bounds.height * 2)
        scrollView.contentSize = screenSizeWithDoubleHeight
        scrollView.pagingEnabled = true
        scrollView.directionalLockEnabled = true
    }
    
    private func setupImages(contentSize: CGSize) {
        //setup the image view
        let imageFrame = CGRectMake(0, 0, contentSize.width, contentSize.height)
        imageView.frame = imageFrame
        
        imageView.contentMode = .ScaleAspectFit
        imageView.backgroundColor = .whiteColor()
        
        //setup the image
        imageView.image = UIImage(named: Constants.PeruseWithWordsImageName)
        
        scrollView.addSubview(imageView)
    }
    
    private func createPageViewController() {
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.PageVCIdentifier) as! UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        
        if Constants.contentImages.count > 0 {
            let firstController = getItemController(0)!
            let startingViewControllers = [firstController] as [AnyObject]
            pageController.setViewControllers(startingViewControllers, direction: .Forward, animated: false, completion: nil)
        }
        
        pageViewController = pageController
        addChildViewController(pageViewController!)
        pageViewController!.view.frame = CGRectMake(0, view.frame.height, view.frame.width, view.frame.height)
        self.scrollView.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
    }
    
    private func setupPageControl() {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.lightGrayColor()
        appearance.currentPageIndicatorTintColor = UIColor.blackColor()
        appearance.backgroundColor = UIColor.clearColor()
    }
    
    private func setupFacebookLoginButton() {
        facebookLoginButton = FBSDKLoginButton()
        facebookLoginButton!.readPermissions = Constants.FacebookPermissions
        facebookLoginButton!.center = view.center
        scrollView.addSubview(facebookLoginButton!)
        facebookLoginButton?.delegate = self
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
            
            let itemController = viewController as! OnboardPageItemViewController
            if itemController.itemIndex > 0 { return getItemController(itemController.itemIndex - 1) }
            return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
            
            let itemController = viewController as! OnboardPageItemViewController
            if itemController.itemIndex + 1 < Constants.contentImages.count {
                return getItemController(itemController.itemIndex + 1)
            }
            return nil
    }
    
    private func getItemController(itemIndex: Int) -> OnboardPageItemViewController? {
        if itemIndex < Constants.contentImages.count {
            let pageItemController = storyboard!.instantiateViewControllerWithIdentifier(Constants.PageItemVCIdentifier) as! OnboardPageItemViewController
            
            //Check for Errors
            assert(Constants.contentImages.count == Constants.titles.count,
                "There should be the same number of content images and titles")
            assert(Constants.titles.count == Constants.captions.count,
                "There should be the same number of titles and captions")
            assert(Constants.contentImages.count == Constants.movies.count,
                "There should be the same number of content images and movie names")
            
            //setup the page item controller
            pageItemController.itemIndex = itemIndex
            pageItemController.imageName = Constants.contentImages[itemIndex] ?? ""
            pageItemController.captionText = Constants.captions[itemIndex]
            pageItemController.titleText = Constants.titles[itemIndex]
            pageItemController.movieName = Constants.movies[itemIndex]
            if let pvc = pageViewController { pageItemController.view.frame = pvc.view.frame }
            return pageItemController
        }
        return nil
    }
    
    // MARK: - Page Indicator
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return Constants.contentImages.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - FBSDKLoginButtonDelegate
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if result == nil { return }
        if !result.isCancelled && result.grantedPermissions.contains("public_profile") && result.grantedPermissions.contains("user_photos") {
            self.segueToProfileSetup()
        } else if let declined = result?.declinedPermissions {
            if declined.contains("user_photos") {
                let dismissTitle = "Log Out"
                let settingsTitle = "Allow Access"
                let alert = UIAlertController(title: Constants.Alert.NoPhotosTitle, message: Constants.Alert.NoPhotosMessage, preferredStyle: .Alert)
                let dismissAction = UIAlertAction(title: dismissTitle, style: .Cancel, handler: { (alertAction) -> Void in
                    FBSDKLoginManager().logOut()
                })
                let settingsAction = UIAlertAction(title: settingsTitle, style: .Default, handler: { [unowned self] (alertAction) -> Void in
                    FBSDKLoginManager().logInWithReadPermissions(["user_photos"], handler: { (loginResult, error) -> Void in
                        if loginResult?.grantedPermissions != nil {
                            if loginResult.grantedPermissions.contains("user_photos") {
                                self.segueToProfileSetup()
                                return
                            }
                        } else if error != nil {
                            println(error.localizedDescription)
                        }
                        FBSDKLoginManager().logOut()
                    })
                    })
                alert.addAction(dismissAction)
                alert.addAction(settingsAction)
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            self.dismissViewControllerAnimated(true) {
                FBSDKLoginManager().logOut()
            }
        }
    }
    
    private func segueToProfileSetup() {
        let initial = presentingViewController as? InitialViewController
        initial?.facebookLoginWasSuccessful = true
        imageView.image = UIImage(named: Constants.PeruseWithoutWordsImageName)
        facebookLoginButton?.hidden = true
    }
    
    func appDidBecomeActive() {
        if let initial = presentingViewController as? InitialViewController {
            if !initial.facebookLoginWasSuccessful { return }
            self.dismissViewControllerAnimated(false) {
                let presentingVC = self.presentingViewController as? InitialViewController
                presentingVC?.segueToCorrectVC()
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {  }
    
    
}