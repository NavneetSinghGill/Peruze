//
//  WriteReviewViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 7/3/15.
//  Copyright (c) 2015 Peruse, LLC. All rights reserved.
//

import UIKit

class WriteReviewViewController: UIViewController, UITextViewDelegate {
    private struct Constants {
        struct NoTitle {
            static let Title = "No Title"
            static let Message = "Oops! Check out the title field. You don't have to leave a full review, but please leave a title."
            static let Cancel = "Dismiss"
        }
        struct NoStarRating {
            static let Title = "No Star Rating"
            static let Message = "I know you may not be thrilled with this person, but at least give them one star! They're still our friend, after all."
            static let Cancel = "Dismiss"
        }
        static let ReviewPlaceholder = "Review (Optional)"
        static let EmptyStarName = "Empty_Star"
        static let FullStarName = "Full_Star"
    }
    @IBOutlet weak var farLeftStar: UIImageView!
    @IBOutlet weak var middleLeftStar: UIImageView!
    @IBOutlet weak var middleStar: UIImageView!
    @IBOutlet weak var middleRightStar: UIImageView!
    @IBOutlet weak var farRightStar: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    private var detailTextView: UITextView!
    private var keyboardOnScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailTextView = UITextView()
        detailTextView.text = Constants.ReviewPlaceholder
        detailTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        detailTextView.textColor = .lightGrayColor()
        detailTextView.scrollEnabled = false
        detailTextView.delegate = self
        scrollView.addSubview(detailTextView)
        updateTextViewSize(detailTextView)
        //Notification Center setup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        detailTextView.frame.origin = CGPointMake(titleTextField.frame.origin.x, titleTextField.frame.maxY + 8)
        updateTextViewSize(detailTextView)
    }
    @IBAction func starTap(sender: UITapGestureRecognizer) {
        var hitTap = false
        let starArray = [farLeftStar, middleLeftStar, middleStar, middleRightStar, farRightStar]
        for i in 0..<starArray.count {
            starArray[i].image = UIImage(named: hitTap ? Constants.EmptyStarName : Constants.FullStarName)
            hitTap = hitTap || CGRectContainsPoint(starArray[i].frame, sender.locationInView(scrollView))
        }
        view.endEditing(true)
    }
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func send(sender: UIBarButtonItem) {
        if farLeftStar.image == UIImage(named: "Empty_Star") {
            let alert = UIAlertController(title: Constants.NoStarRating.Title, message: Constants.NoStarRating.Message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancel = UIAlertAction(title: Constants.NoStarRating.Cancel, style: UIAlertActionStyle.Cancel) { (_) -> Void in }
            alert.addAction(cancel)
            presentViewController(alert, animated: true, completion: nil)
        } else if titleTextField.text.isEmpty {
            let alert = UIAlertController(title: Constants.NoTitle.Title, message: Constants.NoTitle.Message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancel = UIAlertAction(title: Constants.NoTitle.Cancel, style: UIAlertActionStyle.Cancel) { (_) -> Void in }
            alert.addAction(cancel)
            presentViewController(alert, animated: true, completion: nil)
        } else {
            dismissViewControllerAnimated(true){
                //TODO: save review
            }
        }
    }
    private func updateTextViewSize(textView: UITextView) {
        let fixedWidth = titleTextField.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        textView.frame = newFrame;
        scrollView.contentSize = CGSizeMake(view.frame.width, textView.frame.maxY)
    }
    
    //MARK: - Handling Keyboard Display
    func keyboardWillShow(sender: NSNotification) {
        keyboardOnScreen = true
        if let userInfo = sender.userInfo {
            if let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
                let top = navigationController?.navigationBar.frame.maxY ?? 0
                let bottom = keyboardFrame.height
                let insets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
                scrollView.contentInset = insets
                scrollView.scrollIndicatorInsets = insets
                scrollView.scrollRectToVisible(detailTextView.frame, animated: true)
            }
        }
    }
    
    func keyboardWillHide(sender: AnyObject) {
        keyboardOnScreen = false
        UIView.animateWithDuration(0.5) {
            let top = self.navigationController?.navigationBar.frame.maxY ?? 0
            let bottom = self.tabBarController?.tabBar.frame.height ?? 0
            let insets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
            self.scrollView.contentInset = insets
            self.scrollView.scrollIndicatorInsets = insets
            self.updateTextViewSize(self.detailTextView)
        }
    }
    
    //MARK: - Text View Delegate methods
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Review (Optional)" {
            textView.text = ""
            textView.textColor = .blackColor()
        }
        updateTextViewSize(textView)
    }
    func textViewDidChange(textView: UITextView) {
        if textView.text == "Review (Optional)" {
            textView.text = ""
        } else {
            textView.textColor = .blackColor()
        }
        updateTextViewSize(textView)
    }
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.textColor = .lightGrayColor()
            textView.text = "Review (Optional)"
        }
        updateTextViewSize(textView)
    }
}
