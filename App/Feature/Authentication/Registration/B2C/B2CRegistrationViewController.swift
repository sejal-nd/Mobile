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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = NSLocalizedString("Register", comment: "")
        addCloseButton()

        webView.navigationDelegate = self
        webView.isHidden = true

        #warning("Todo, replace with actual webview when it is ready")
        if let url = URL(string: "https://www.apple.com") {
            webView.load(NSURLRequest(url: url) as URLRequest)
        }
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
}

extension B2CRegistrationViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
}
