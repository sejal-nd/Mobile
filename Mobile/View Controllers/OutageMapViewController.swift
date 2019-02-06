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
    let opco = Environment.shared.opco
    
    var unauthenticatedExperience = false
    
    var hasPressedStreetlightOutageMapButton = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url: URL
        let a11yLabel: String
        if hasPressedStreetlightOutageMapButton {
            title = NSLocalizedString("Street Light Map", comment: "")
            url = URL(string: "https://comed.streetlightoutages.com")!
            a11yLabel = NSLocalizedString("This is an outage map showing the street lights that are currently experiencing an outage.", comment: "")
        } else {
            title = NSLocalizedString("Outage Map", comment: "")
            url = URL(string: Environment.shared.outageMapUrl)!
            a11yLabel = NSLocalizedString("This is an outage map showing the areas that are currently experiencing an outage. You can check your outage status on the main Outage section of the app.", comment: "")
        }
            
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.isHidden = true
        
        webView.load(URLRequest(url: url))
        webView.isAccessibilityElement = false
        webView.accessibilityLabel = a11yLabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(unauthenticatedExperience) {
            Analytics.log(event: .viewOutageMapUnAuthOfferComplete)
        }
    }

}

extension OutageMapViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        
        webView.isHidden = false
        webView.isAccessibilityElement = true
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
}
