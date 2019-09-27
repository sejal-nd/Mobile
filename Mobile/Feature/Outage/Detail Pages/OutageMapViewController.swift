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

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    let opco = Environment.shared.opco
    
    var unauthenticatedExperience = false
    
    var hasPressedStreetlightOutageMapButton = false
    
    var urlString: String?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        let a11yLabel: String
        if hasPressedStreetlightOutageMapButton {
            title = NSLocalizedString("Street Light Map", comment: "")
            a11yLabel = NSLocalizedString("This is an outage map showing the street lights that are currently experiencing an outage.", comment: "")
        } else {
            title = NSLocalizedString("Outage Map", comment: "")
            a11yLabel = NSLocalizedString("This is an outage map showing the areas that are currently experiencing an outage. You can check your outage status on the main Outage section of the app.", comment: "")
        }
        
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.load(URLRequest(url: url))
        webView.isAccessibilityElement = false
        webView.accessibilityLabel = a11yLabel
        webView.scrollView.isScrollEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if unauthenticatedExperience {
            GoogleAnalytics.log(event: .viewOutageMapUnAuthOfferComplete)
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
