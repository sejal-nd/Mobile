//
//  OutageMapViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class OutageMapViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    let opco = Environment.sharedInstance.opco
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Outage Map", comment: "")
        
        webView.delegate = self
        
        let url = URL(string: Environment.sharedInstance.outageMapUrl)!
        webView.loadRequest(URLRequest(url: url))
        webView.isAccessibilityElement = false
        webView.accessibilityLabel = "This is an outage map showing the areas that are currently experiencing an outage."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }

}

extension OutageMapViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loadingIndicator.isHidden = true
        
        webView.isAccessibilityElement = true
    }
    
}
