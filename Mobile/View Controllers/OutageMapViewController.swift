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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Outage Map", comment: "")

        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.isHidden = true

        let url = URL(string: Environment.shared.outageMapUrl)!
        webView.load(URLRequest(url: url))
        webView.isAccessibilityElement = false
        webView.accessibilityLabel = NSLocalizedString("This is an outage map showing the areas that are currently experiencing an outage. You can check your outage status on the main Outage section of the app.", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        } else { // Sent from unauthenticated user experience
            navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
            navigationController?.navigationBar.barTintColor = .primaryColor
            navigationController?.navigationBar.isTranslucent = false
            
            let titleDict: [NSAttributedStringKey: Any] = [
                .foregroundColor: UIColor.white,
                .font: OpenSans.bold.of(size: 18)
            ]
            navigationController?.navigationBar.titleTextAttributes = titleDict
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(unauthenticatedExperience) {
            Analytics.log(event: .ViewOutageMapUnAuthOfferComplete)
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
