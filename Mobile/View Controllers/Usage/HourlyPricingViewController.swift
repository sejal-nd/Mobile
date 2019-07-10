//
//  HourlyPricingViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class HourlyPricingViewController: UIViewController {
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    let accountService = ServiceFactory.createAccountService()
    
    var accountDetail: AccountDetail! // Passed from SmartEnergyRewardsViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.insertSubview(webView, belowSubview: loadingIndicator)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.navigationDelegate = self
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        let urlString: String
        if accountDetail.isHourlyPricing {
            urlString = String(format: "https://hourlypricing.comed.com/rrtpmobile/servlet?type=home&account=%@", accountDetail.accountNumber)
        } else {
            urlString = "https://hourlypricing.comed.com"
        }
        
        guard let url = URL(string: urlString) else {
            loadingIndicator.isHidden = true
            errorLabel.isHidden = false
            return
        }
     
        webView.load(URLRequest(url: url))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

}

extension HourlyPricingViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
        webView.isHidden = false
        errorLabel.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.isHidden = true
        webView.isHidden = true
        errorLabel.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.isHidden = true
        webView.isHidden = true
        errorLabel.isHidden = false
    }
}
