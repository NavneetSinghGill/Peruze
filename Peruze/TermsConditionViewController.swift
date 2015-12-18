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
        initialSetup()
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