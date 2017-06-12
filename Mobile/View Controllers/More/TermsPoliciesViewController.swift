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
    var viewAppeared = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        title = NSLocalizedString("Terms and Policies", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.textContainerInset = UIEdgeInsetsMake(10, 29, 10, 29)
        textView.attributedText = viewModel.attributedTermsString
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Content was appearing already scrolled initially so this fixes it
        if !viewAppeared {
            textView.setContentOffset(.zero, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewAppeared = true
    }
    
}
