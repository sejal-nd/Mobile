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
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var agreeCheckbox: Checkbox!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var agreeView: UIView!
    @IBOutlet weak var agreeLabel: UILabel!
    
    private let viewModel = TermsPoliciesViewModel()
    
    let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Policies and Terms", comment: "")
        
        agreeView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)

        agreeCheckbox.rx.isChecked.bind(to: continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        
        agreeLabel.textColor = .deepGray
        agreeLabel.font = SystemFont.regular.of(textStyle: .headline)
        agreeLabel.text = viewModel.agreeLabelText
        
        accessibilitySetup()
        
        let request = URLRequest(url: viewModel.termPoliciesURL)
        webView.load(request)
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
        
        agreeCheckbox.isAccessibilityElement = true
        agreeCheckbox.accessibilityLabel = agreeLabel.text
        
        self.view.accessibilityElements = [webView, agreeCheckbox, continueButton] as [UIView]
    }
    
}
