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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Terms and Policies", comment: "")

        if UIDevice.current.userInterfaceIdiom == .phone {
            extendedLayoutIncludesOpaqueBars = true
        }

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewAppeared = true
    }
    
}
