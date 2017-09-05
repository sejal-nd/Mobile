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
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var agreeView: UIView!
    @IBOutlet weak var agreeLabel: UILabel!
    
    let viewModel = TermsPoliciesViewModel()
    var viewAppeared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Policies and Terms", comment: "")
        
        let url = viewModel.termPoliciesURL
        webView.delegate = self
        webView.backgroundColor = .white
        webView.loadRequest(URLRequest(url: url))

        agreeView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)

        _ = agreeSwitch.rx.isOn.bind(to: continueButton.rx.isEnabled)
        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        
        agreeLabel.font = SystemFont.regular.of(size: 15)
        agreeLabel.text = viewModel.agreeLabelText;
        accessibilitySetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.tintColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewAppeared = true
    }
    
    private func accessibilitySetup() {
        agreeLabel.isAccessibilityElement = false
        
        agreeSwitch.isAccessibilityElement = true
        agreeSwitch.accessibilityLabel = agreeLabel.text
        
        self.view.accessibilityElements = [webView, agreeSwitch, continueButton]
    }
    
    @IBAction func onContinuePress() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.HasAcceptedTerms)
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
}

extension LoginTermsPoliciesViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
    
}
