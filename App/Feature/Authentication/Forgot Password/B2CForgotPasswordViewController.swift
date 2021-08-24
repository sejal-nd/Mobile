//
//  B2CForgotPasswordViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/5/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit
import Toast_Swift

class B2CForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate: ChangePasswordViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = NSLocalizedString("Reset Password", comment: "")
        addCloseButton()
        
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        loadWebView()
    }
    
    private func loadWebView() {
        let resetPasswordURLString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_RESETPASSWORD_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=https%3A%2F%2Fjwt.ms&scope=openid&response_type=id_token&prompt=login"
        if let url = URL(string: resetPasswordURLString) {
            webView.load(NSURLRequest(url: url) as URLRequest)
        }
    }
    
    private func success() {
        delegate?.changePasswordViewControllerDidChangePassword(self)
        dismiss(animated: true, completion: nil)
    }
}

extension B2CForgotPasswordViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString,
           urlString.contains("credentialretrieval-passwordentry-mobile") {
            success()
        } else if let urlString = webView.url?.absoluteString,
                  urlString.contains("credential-retrieval/find-account") {
            // Reset web view
            webView.stopLoading()
            
            // trigger native UI
            performSegue(withIdentifier: "forgotUsernameB2cSegue", sender: self)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
}
