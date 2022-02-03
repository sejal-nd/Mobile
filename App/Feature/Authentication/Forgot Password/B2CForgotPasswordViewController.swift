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
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDescription: UILabel!
    weak var delegate: ChangePasswordViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = NSLocalizedString("Reset Password", comment: "")
        addCloseButton()
        
        webView.navigationDelegate = self
        webView.isHidden = true
        // Observe JS for analytics
        webView.configuration.userContentController.add(self, name: "firebase")
        
        errorImage.tintColor = .attentionOrange
        errorTitle.font = SystemFont.semibold.of(textStyle: .title3)
        errorTitle.textColor = .deepGray
        errorDescription.font = SystemFont.regular.of(textStyle: .footnote)
        errorDescription.textColor = .deepGray
        errorView.isHidden = true
        
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
        } else if let urlString = webView.url?.absoluteString,
                   urlString.contains("SelfAsserted/error") {
             self.errorView.isHidden = false
             self.loadingIndicator.isHidden = true
             self.webView.isHidden = true
         }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
}

// MARK: Analytics

extension B2CForgotPasswordViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let command = body["command"] as? String,
              let name = body["name"] as? String else { return }
        
        if command == "logEvent" {
            if name == GoogleAnalyticsEvent.forgotPasswordOffer.rawValue {
                FirebaseUtility.logEvent(.login(parameters: [.forgot_password_press]))
                GoogleAnalytics.log(event: .forgotPasswordOffer)
            }
            
            if name == GoogleAnalyticsEvent.forgotPasswordComplete.rawValue {
                FirebaseUtility.logEvent(.forgotPassword(parameters: [.complete]))
                GoogleAnalytics.log(event: .forgotPasswordComplete)
            }
        }
    }
}
