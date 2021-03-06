//
//  FriendsViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 30/11/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import SwiftLog

//import Social

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    struct FriendsDataAndProfilePic {
        var friendData: NSDictionary!
        var profileImage: CircleImage?
        var isInvited: Bool!
    }
    var taggableFriendsData = [FriendsDataAndProfilePic]()
    var searchedFriendsData = [FriendsDataAndProfilePic]()
    var selectedFriendsToInvite: NSMutableArray = []
    
    private struct Constants {
        static let TableViewRowHeight: CGFloat = 50
        static let kFriendsTableViewCellIdentifier = "TableViewCellIdentifier"
        static let FriendsTableViewNibName = "FriendsTableViewCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         title = "Invite Friends"
        navigationController?.navigationBar.tintColor = .redColor()
        view.backgroundColor = .whiteColor()
        getTaggableFriends()
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "backButtonTapped"), animated: true)
//        let rightBarButton = UIBarButtonItem(title: "Invite", style: .Plain, target: self, action: "postInviteOnFacebook")
//        self.navigationItem.setRightBarButtonItem(rightBarButton, animated: true)
        self.searchTextField.placeholder = "Search for friends"
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow", name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.searchTextField.resignFirstResponder()
    }
    
    func getTaggableFriends() {
         self.activityIndicatorView.startAnimating()
        let request = FBSDKGraphRequest(graphPath:"/me/taggable_friends?limit=5000", parameters: ["fields":"name,id,picture.fields(url),first_name,last_name,context"]);
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            if error == nil {
                logw("Taggable Friends are : \(result)")
                
                var resultsArray = result.valueForKey("data") as! NSArray
                resultsArray = resultsArray.sort { (element1, element2) -> Bool in
                    return (element1.valueForKey("name") as! String) < (element2.valueForKey("name") as! String)
                }
                
                self.taggableFriendsData = []
                self.searchedFriendsData = []
                for friendData in resultsArray {
                    let newFriendData = FriendsDataAndProfilePic(friendData: friendData as! NSDictionary, profileImage: CircleImage(),isInvited: false)
                    newFriendData.profileImage?.image = nil

                    let facebookProfileUrl = ((friendData.valueForKey("picture") as! NSDictionary).valueForKey("data") as! NSDictionary).valueForKey("url") as! String
                        let url = NSURL(string: facebookProfileUrl)
                        if let data = NSData(contentsOfURL: url!) {
                            newFriendData.profileImage?.circleView?.layer.cornerRadius = 0
                            newFriendData.profileImage?.image = UIImage(data: data)
                        }

                    self.taggableFriendsData.append(newFriendData)
                    self.searchedFriendsData.append(newFriendData)
                    
                    dispatch_async(dispatch_get_main_queue()){
                        self.activityIndicatorView.stopAnimating()
                        self.tableView.reloadData()
                    }
                }
                logw("\(_stdlib_getDemangledTypeName(self))) \(__FUNCTION__) taggable Friends: \(self.taggableFriendsData.count)")
            } else {
                logw("Error Getting Friends \(error)");
            }
        }
        dispatch_async(dispatch_get_main_queue()){
            self.tableView.reloadData()
        }
    }
    
    //Mark: - Tableview delefate and datasource methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchedFriendsData.count == 0 && searchTextField.text?.characters.count == 0{
            self.searchedFriendsData = self.taggableFriendsData
        }
        return self.searchedFriendsData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let nib = UINib(nibName: Constants.FriendsTableViewNibName, bundle: nil)
//        tableView.registerNib(nib, forCellReuseIdentifier: Constants.kFriendsTableViewCellIdentifier)
        var cell = tableView.dequeueReusableCellWithIdentifier(Constants.kFriendsTableViewCellIdentifier, forIndexPath: indexPath) as? FriendsTableViewCell
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: Constants.kFriendsTableViewCellIdentifier) as? FriendsTableViewCell
        }
        cell?.selectionStyle = UITableViewCellSelectionStyle.None
        var parsedObject = self.searchedFriendsData[indexPath.row]
        let userDict =  parsedObject.friendData
        cell!.nameLabel.text = userDict?.valueForKey("name") as? String
        cell!.friendDataDict = userDict
        
        if parsedObject.profileImage?.image != nil {
            cell?.profileImageView.image = parsedObject.profileImage?.image
        }
        cell?.inviteButton.layer.cornerRadius = 5
        cell?.inviteButton.layer.borderWidth = 1
        cell?.inviteButton.layer.borderColor = UIColor(red: 188/255, green: 188/255, blue: 188/255, alpha: 0.5).CGColor
        cell?.inviteButton.layer.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1).CGColor
        if parsedObject.isInvited == false {
            cell?.inviteButton.setTitle("Invite", forState: UIControlState.Normal)
            cell?.inviteButton.hidden = false
            cell?.inviteButton.enabled = true
        } else {
            cell?.inviteButton.setTitle("Invited", forState: UIControlState.Normal)
            cell?.inviteButton.hidden = true
            cell?.inviteButton.enabled = false
        }
        
        if selectedFriendsToInvite.containsObject(cell!.friendDataDict) {
            cell?.inviteButton.setTitle("Invited", forState: UIControlState.Normal)
        }
        
        cell?.inviteTapBlock = {
            if parsedObject.isInvited == false {
                cell?.inviteButton.setTitle("Invited", forState: UIControlState.Normal)
                self.selectedFriendsToInvite = []
                self.selectedFriendsToInvite.addObject((cell?.friendDataDict)!)
                self.postInviteOnFacebook()
            }
            parsedObject.isInvited = true
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//        let cell = tableView.cellForRowAtIndexPath(indexPath) as! FriendsTableViewCell
//        if cell.accessoryType == UITableViewCellAccessoryType.None {
//            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
//            selectedFriendsToInvite.addObject(cell.friendDataDict)
//        } else {
//            cell.accessoryType = UITableViewCellAccessoryType.None
//            selectedFriendsToInvite.removeObject(cell.friendDataDict)
//        }
    }
    
    func backButtonTapped() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func postInviteOnFacebook() {
        //perform tagging
        let selectedFriendsIds : NSArray = selectedFriendsToInvite.valueForKey("id") as! NSArray
        let idsString = selectedFriendsIds.componentsJoinedByString(",")
        print("Ids = \(idsString)")
        postOnFaceBook(idsString)
        
        
    }
    
    @IBAction func textFieldChanged(sender: UITextField) {
        sender.becomeFirstResponder()
        self.searchedFriendsData = []
        for parsedFriendData in self.taggableFriendsData {
            if (parsedFriendData.friendData.valueForKey("name") as! String).lowercaseString.containsString(sender.text!.lowercaseString) {
                self.searchedFriendsData.append(parsedFriendData)
            }
        }
        self.tableView.reloadData()
    }
    
    
    
    //MARK: - Post On facebook
    func postOnFaceBook(idsString : String) {
        if !FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions") {
            let manager = FBSDKLoginManager()
            manager.logInWithPublishPermissions(["publish_actions"], handler: { (loginResult, error) -> Void in
                if !loginResult.grantedPermissions.contains("publish_actions") {
                    self.performPost(idsString)
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        } else {
//            self.activityIndicatorView.startAnimating()
            performPost(idsString)
        }
    }
    
    
    func performPost(idsString : String) {
        let params: NSMutableDictionary = [:]
        params.setValue("1", forKey: "setdebug")
        let me = Person.MR_findFirstByAttribute("me", withValue: true)
        params.setValue((me.valueForKey("firstName") as! String) + " " + (me.valueForKey("lastName") as! String) , forKey: "senderId")
        params.setValue("facebook", forKey: "shareType")
        Branch.getInstance().getShortURLWithParams(params as [NSObject : AnyObject], andCallback: { (url: String!, error: NSError!) -> Void in
            if (error == nil) {
                logw("url: \(url)")
                let urlString = "\(url)"
                let request = FBSDKGraphRequest(graphPath: "me/feed", parameters:[ "message" : "Trade your old valuables & services with friends in your social network \n- try Peruze today!", "link" : urlString,"picture": "https://www.peruzenow.com/images/devices.png","caption":"Change how you exchange","title":true,"description":"Peruze is an exciting new mobile marketplace where you can find things you want in exchange for stuff you no longer need.", "tags":idsString],  HTTPMethod:"POST")
                request.startWithCompletionHandler({ (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                    //set error and return
                    if error != nil {
                        print("Post failed: \(error)")
                    } else {
                        print("Post success")
//                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    self.activityIndicatorView.stopAnimating()
                })
            }
        })
        
    }
}
