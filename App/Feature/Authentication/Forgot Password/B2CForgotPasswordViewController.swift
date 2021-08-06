//
//  B2CForgotPasswordViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/5/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class B2CForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        #warning("Todo, replace todo below with the javascript PSOT message that web view will send.")
        configuration.userContentController.add(self, name: "todo")
        return configuration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = NSLocalizedString("Reset Password", comment: "")
        addCloseButton()
        
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        let resetPasswordURLString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_RESETPASSWORD_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=https%3A%2F%2Fjwt.ms&scope=openid&response_type=id_token&prompt=login"
        if let url = URL(string: resetPasswordURLString) {
            webView.uiDelegate = self
            webView.load(NSURLRequest(url: url) as URLRequest)
        }
    }
}

extension B2CForgotPasswordViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
}

extension B2CForgotPasswordViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return WKWebView(frame: webView.frame,
                         configuration: webViewConfiguration)
    }
}

extension B2CForgotPasswordViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        #warning("Todo, need to intercept a javascript function here from webview")
        print("javascript sending \(message.name), body: \(message.body)")
    }
}
