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
    
    private let viewModel = TermsPoliciesViewModel()
    private var viewAppeared = false
    
    // MARk: - View Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        title = NSLocalizedString("Policies and Terms", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = viewModel.termPoliciesURL
        setupWKWebView(with: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.styleNavbar()
    }
    
    
    // MARK: - Helper
    
    private func setupWKWebView(with url: URL) {
        // Programtically Configure WKWebView due to a bug with using IB WKWebView before iOS 11
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // Prevents status bar color flash when pushed from MoreViewController
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
