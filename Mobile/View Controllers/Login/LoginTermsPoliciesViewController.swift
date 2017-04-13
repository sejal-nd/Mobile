//
//  LoginTermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginTermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var agreeSwitch: Switch!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var agreeView: UIView!
    @IBOutlet weak var agreeLabel: UILabel!
    
    let viewModel = TermsPoliciesViewModel()
    var viewAppeared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Terms and Policies", comment: "")
        
        textView.textContainerInset = UIEdgeInsetsMake(26, 29, 26, 29)
        textView.attributedText = viewModel.attributedTermsString

        agreeView.layer.shadowColor = UIColor.black.cgColor
        agreeView.layer.shadowOffset = CGSize(width: 0, height: 0)
        agreeView.layer.shadowOpacity = 0.1
        agreeView.layer.shadowRadius = 2
        agreeView.layer.masksToBounds = false

        _ = agreeSwitch.rx.isOn.bindTo(continueButton.rx.isEnabled)
        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        
        agreeLabel.text = viewModel.agreeLabelText;
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
    
    @IBAction func onContinuePress() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.HasAcceptedTerms)
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    

    
}
