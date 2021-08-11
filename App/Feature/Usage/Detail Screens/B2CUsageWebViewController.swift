//
//  B2CUsageWebViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/6/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class B2CUsageWebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
        
    var accountDetail: AccountDetail?
    
    enum WidgetName: String {
        case usage = "data-browser"
        case ser, pesc = "peak-time-rebate"
        
        var navigationTitle: String {
            switch self {
            case .usage:
                return "Usage Data"
            case .ser:
                return "Smart Energy Rewards"
            case .pesc:
                return "Peak Energy Savings History"
            }
        }
    }
    var widget: WidgetName = .usage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString(widget.navigationTitle, comment: "")
                
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        fetchJWT()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func fetchJWT() {
        let request = B2CoPowerJWTRequest(clientID: Configuration.shared.b2cClientID,
                                          refreshToken: UserSession.refreshToken,
                                          nonce: accountDetail?.accountNumber ?? "")
        UsageService.fetchOpowerToken(request: request) { [weak self] result in
            switch result {
            case .success(let tokenResponse):
                guard let self = self else { return }
                self.errorLabel.isHidden = true
                
                self.loadWebView(token: tokenResponse.token ?? "")
            case .failure:
                guard let self = self else { return }
                self.errorLabel.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    private func loadWebView(token: String) {
        let oPowerWidgetURL = Configuration.shared.b2cOpowerWidgetURLString
        if let url = URL(string: oPowerWidgetURL) {
            var request = NSURLRequest(url: url) as URLRequest
            request.addValue(token, forHTTPHeaderField: "accessToken")
            request.addValue(widget.rawValue, forHTTPHeaderField: "opowerWidgetId")
            webView.load(request)
        }
    }
}

extension B2CUsageWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorLabel.isHidden = false
        loadingIndicator.isHidden = true
        webView.isHidden = true
    }
}
