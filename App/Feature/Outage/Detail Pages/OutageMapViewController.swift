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
    let opco = Configuration.shared.opco
    
    var unauthenticatedExperience = false
    
    var hasPressedStreetlightOutageMapButton = false
    
    private var urlString: String?
    
    // Feature Flag
    private var streetlightOutageMapURLString = FeatureFlagUtility.shared.string(forKey: .streetlightMapURL)
    private var outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let a11yLabel: String
        if hasPressedStreetlightOutageMapButton {
            title = NSLocalizedString("Street Light Map", comment: "")
            urlString = streetlightOutageMapURLString
            a11yLabel = NSLocalizedString("This is an outage map showing the street lights that are currently experiencing an outage.", comment: "")
        } else {
            title = NSLocalizedString("Outage Map", comment: "")
            urlString = outageMapURLString
            a11yLabel = NSLocalizedString("This is an outage map showing the areas that are currently experiencing an outage. You can check your outage status on the main Outage section of the app.", comment: "")
        }
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
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
        
        if urlString?.isEmpty ?? true {
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("The map is currently unavailable. Please try again later.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
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

extension OutageMapViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
            let url = navigationAction.request.url,
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        
            // force http links to load over https
            if url.scheme == "http" {
                urlComponents.scheme = "https"
            }
            
            if let newUrl = urlComponents.url {
                webView.load(URLRequest(url: newUrl))
            }
        }
        return nil;
    }
}
