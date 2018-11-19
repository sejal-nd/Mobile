//
//  WebFormViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 11/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

protocol WebFormViewControllerDelegate: class {
    func webFormViewController(_ viewController: WebFormViewController, didRedirectToUrl url: URL)
}

class WebFormViewController: UIViewController {
    
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    
    private let url: URL
    private let redirectUrl: String?
    
    weak var delegate: WebFormViewControllerDelegate?
    
    init(title: String, url: URL, redirectUrl: String? = nil) {
        self.url = url
        self.redirectUrl = redirectUrl
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white

        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.isHidden = false
        
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero , configuration: webConfiguration)
        webView.navigationDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setColoredNavBar()
    }

}

extension WebFormViewController: WKNavigationDelegate {
    
    /// One of these two methods will catch the redirect.
    /// We might want to remove one when we figure out which it will be.
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url, let redirectUrl = redirectUrl,
            url.absoluteString.starts(with: redirectUrl) {
            delegate?.webFormViewController(self, didRedirectToUrl: url)
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = webView.url, let redirectUrl = redirectUrl,
            url.absoluteString.starts(with: redirectUrl) {
            decisionHandler(.cancel)
            delegate?.webFormViewController(self, didRedirectToUrl: url)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
    }
}
