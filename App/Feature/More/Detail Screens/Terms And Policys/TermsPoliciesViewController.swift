//
//  TermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class TermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    private let viewModel = TermsPoliciesViewModel()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Policies and Terms", comment: "")
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        let request = URLRequest(url: viewModel.termPoliciesURL)
        webView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}

extension TermsPoliciesViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           !url.absoluteString.contains("ex path") {
            UIApplication.shared.openUrlIfCan(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension TermsPoliciesViewController: WKUIDelegate {
    
}
