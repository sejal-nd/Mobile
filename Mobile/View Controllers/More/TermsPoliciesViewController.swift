//
//  TermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    let viewModel = TermsPoliciesViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Terms and Policies", comment: "")
        
        textView.textContainerInset = UIEdgeInsetsMake(26, 29, 26, 29)
        textView.attributedText = viewModel.attributedTermsString
    }

}
