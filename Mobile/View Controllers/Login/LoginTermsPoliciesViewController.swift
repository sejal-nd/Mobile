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
        
        textView.textContainerInset = UIEdgeInsetsMake(10, 29, 10, 29)
        textView.attributedText = viewModel.attributedTermsString

        agreeView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.blackText,
            NSFontAttributeName: OpenSans.bold.ofSize(18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
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
