//
//  WebViewController.swift
//  Mobile
//
//  Created by Sam Francis on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var webContainerView: UIView!
    private var webView: WKWebView!
    
    private var navTitle: String
    private var url: URL
    
    
    init(title: String, url: URL) {
        navTitle = title
        self.url = url
        
        super.init(nibName: WebViewController.className, bundle: nil)
        
        modalPresentationStyle = .formSheet // For iPad
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        navBarView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        titleLabel.textColor = .blackText
        titleLabel.text = navTitle
        
        setupWKWebView(with: url)
    }
    
    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Helper
    
    private func setupWKWebView(with url: URL) {
        loadingIndicator.isHidden = false
        
        // Programtically Configure WKWebView due to a bug with using IB WKWebView before iOS 11
        let webConfiguration = WKWebViewConfiguration()
        let customFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 0.0, height: webContainerView.frame.size.height))
        webView = WKWebView(frame: customFrame , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainerView.addSubview(webView)
        webView.topAnchor.constraint(equalTo: webContainerView.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: webContainerView.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: webContainerView.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webContainerView.bottomAnchor).isActive = true
        webView.heightAnchor.constraint(equalTo: webContainerView.heightAnchor).isActive = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
    }
    
}
