//
//  TermsConditionViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 16/12/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation

class TermsConditionViewController: UIViewController {
    struct FileOnDemand {
        static let terms = 1
        static let safety = 2
        static let privacyPolicy = 3
    }
    var fileToShow: Int!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = ""
        textView.editable = false
        navigationController?.navigationBar.tintColor = .redColor()
        view.backgroundColor = .whiteColor()
        let rightBarButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "backButtonTapped")
        self.navigationItem.setLeftBarButtonItem(rightBarButton, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initialSetup()
    }
    
    func backButtonTapped() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func initialSetup() {
        if fileToShow == FileOnDemand.terms {
            title = "Terms and conditions"
            let rtfPath = NSBundle.mainBundle().URLForResource("Terms", withExtension: "rtf")
            do {
                let attributedStringWithRtf = try NSAttributedString(fileURL: rtfPath!, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
                self.textView.attributedText = attributedStringWithRtf
            }
            catch {
                
            }
        } else if fileToShow == FileOnDemand.safety {
            title = "Safety"
            let rtfPath = NSBundle.mainBundle().URLForResource("PeruzeSafety", withExtension: "rtf")
            do {
                let attributedStringWithRtf = try NSAttributedString(fileURL: rtfPath!, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
                self.textView.attributedText = attributedStringWithRtf
            }
            catch {
                
            }
        } else if fileToShow == FileOnDemand.privacyPolicy {
            title = "Privacy Policy"
            let rtfPath = NSBundle.mainBundle().URLForResource("PeruzePrivacyPolicy", withExtension: "rtf")
            do {
                let attributedStringWithRtf = try NSAttributedString(fileURL: rtfPath!, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
                self.textView.attributedText = attributedStringWithRtf
            }
            catch {
                
            }
        }
        self.textView.selectedRange = NSMakeRange(3, 0)
    }
}