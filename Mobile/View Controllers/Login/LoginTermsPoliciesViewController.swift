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
import WebKit

class LoginTermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var webContainerView: UIView!
    @IBOutlet weak var agreeSwitch: Switch!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var agreeView: UIView!
    @IBOutlet weak var agreeLabel: UILabel!
    private var webView: WKWebView!
    
    private let viewModel = TermsPoliciesViewModel()
    private var viewAppeared = false
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Policies and Terms", comment: "")
        
        let url = viewModel.termPoliciesURL
        setupWKWebView(with: url)

        agreeView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)

        _ = agreeSwitch.rx.isOn.bind(to: continueButton.rx.isEnabled)
        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        
        agreeLabel.font = SystemFont.regular.of(size: 15)
        agreeLabel.text = viewModel.agreeLabelText
        accessibilitySetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.styleNavbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewAppeared = true
    }
    

    // MARK: - Actions
    
    @IBAction func onContinuePress() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.hasAcceptedTerms)
        // Set "Report Outage" quick action
        RxNotifications.shared.configureQuickActions.onNext(false)
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Helper
    
    private func accessibilitySetup() {
        agreeLabel.isAccessibilityElement = false
        
        agreeSwitch.isAccessibilityElement = true
        agreeSwitch.accessibilityLabel = agreeLabel.text
        
        self.view.accessibilityElements = [webView, agreeSwitch, continueButton] as [UIView]
    }
    
    private func setupWKWebView(with url: URL) {
        // Programtically Configure WKWebView due to a bug with using IB WKWebView before iOS 11
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainerView.addSubview(webView)
        webView.topAnchor.constraint(equalTo: webContainerView.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: webContainerView.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: webContainerView.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webContainerView.bottomAnchor).isActive = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
}
