//
//  B2CRegistrationViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/5/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class B2CRegistrationViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate: RegistrationViewControllerDelegate?
    
    var validatedAccount: ValidatedAccountResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        addCloseButton()
        
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        fetchJWT()
    }
    
    private func fetchJWT() {
        let request = B2CJWTRequest(customerID: validatedAccount?.accounts.first?.accountNumber ?? "",
                                    ebillEligible: validatedAccount?.isEbill ?? true,
                                    type: validatedAccount?.type?.first ?? "residential")
        RegistrationService.fetchB2CJWT(request: request) { [weak self] result in
            switch result {
            case .success(let token):
                guard let self = self else { return }
                self.errorLabel.isHidden = true
                
                self.loadWebView(token: token)
            case .failure:
                guard let self = self else { return }
                self.errorLabel.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    private func loadWebView(token: String) {
        let registrationURLString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_REGISTER_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=https%3A%2F%2Fjwt.ms&scope=openid&response_type=id_token&prompt=login&id_token_hint=\(token)"
        if let url = URL(string: registrationURLString) {
            webView.load(NSURLRequest(url: url) as URLRequest)
        }
    }
    
    private func success() {
        delegate?.registrationViewControllerDidRegister(self)
        dismiss(animated: true, completion: nil)
    }
}

extension B2CRegistrationViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString,
           urlString.contains("todo") {
            #warning("TODO, URL contains todo above")
            success()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorLabel.isHidden = false
        loadingIndicator.isHidden = true
        webView.isHidden = true
    }
}
