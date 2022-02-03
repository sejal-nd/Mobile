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
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDescription: UILabel!
    
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
        
        var identifier: String {
            switch self {
            case .usage:
                return "data-browser"
            case .ser, .pesc:
                return "peak-time-rebate"
            }
        }
    }
    var widget: WidgetName = .usage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString(widget.navigationTitle, comment: "")
                
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorImage.tintColor = .attentionOrange
        errorTitle.font = SystemFont.semibold.of(textStyle: .title3)
        errorTitle.textColor = .deepGray
        errorDescription.font = SystemFont.regular.of(textStyle: .footnote)
        errorDescription.textColor = .deepGray
        errorView.isHidden = true
        
        fetchJWT()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func fetchJWT() {
        let request = B2CTokenRequest(scope: "https://\(Configuration.shared.b2cTenant).onmicrosoft.com/opower/opower_connect",
                                   nonce: accountDetail?.accountNumber ?? "",
                                   grantType: "refresh_token",
                                   responseType: "token",
                                   refreshToken: UserSession.refreshToken)
        UsageService.fetchOpowerToken(request: request) { [weak self] result in
            switch result {
            case .success(let tokenResponse):
                guard let self = self else { return }
                self.errorView.isHidden = true

                self.loadWebView(token: tokenResponse.token ?? "")
            case .failure:
                guard let self = self else { return }
                self.errorView.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    private func loadWebView(token: String) {
        let oPowerWidgetURL = Configuration.shared.getSecureOpCoOpowerURLString(accountDetail?.opcoType ?? Configuration.shared.opco)
        if let url = URL(string: oPowerWidgetURL) {
            var request = NSURLRequest(url: url) as URLRequest
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "accessToken")
            request.addValue(widget.identifier, forHTTPHeaderField: "opowerWidgetId")
            request.addValue(accountDetail?.utilityCode ?? Configuration.shared.opco.rawValue, forHTTPHeaderField: "opco")
            request.addValue(accountDetail?.state ?? "MD", forHTTPHeaderField: "state")
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
        errorView.isHidden = false
        loadingIndicator.isHidden = true
        webView.isHidden = true
        Log.error("Error loading usage web view: \(error)\n\(error.localizedDescription)")
    }
}
