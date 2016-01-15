//
//  TermsConditionViewController.swift
//  Peruze
//
//  Created by stplmacmini11 on 16/12/15.
//  Copyright © 2015 Peruze, LLC. All rights reserved.
//

import Foundation

class TermsConditionViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = ""
        textView.editable = false
        title = "Terms and conditions"
        navigationController?.navigationBar.tintColor = .redColor()
        view.backgroundColor = .whiteColor()
//        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "backButtonTapped"), animated: true)
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
        let rtfPath = NSBundle.mainBundle().URLForResource("Terms", withExtension: "rtf")
        do {
            let attributedStringWithRtf = try NSAttributedString(fileURL: rtfPath!, options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType], documentAttributes: nil)
            self.textView.attributedText = attributedStringWithRtf
        }
        catch {
            
        }
    }
}