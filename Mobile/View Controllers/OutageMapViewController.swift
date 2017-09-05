//
//  OutageMapViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class OutageMapViewController: UIViewController {

    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    let opco = Environment.sharedInstance.opco
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Outage Map", comment: "")

        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.isHidden = true

        let url = URL(string: Environment.sharedInstance.outageMapUrl)!
        webView.load(URLRequest(url: url))
        webView.isAccessibilityElement = false
        webView.accessibilityLabel = NSLocalizedString("This is an outage map showing the areas that are currently experiencing an outage. You can check your outage status on the main Outage section of the app.", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }

}

extension OutageMapViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        
        webView.isHidden = false
        webView.isAccessibilityElement = true
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
    }
    
}
