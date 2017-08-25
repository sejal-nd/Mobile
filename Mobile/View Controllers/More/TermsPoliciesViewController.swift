//
//  TermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    let viewModel = TermsPoliciesViewModel()
    var viewAppeared = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        title = NSLocalizedString("Policies and Terms", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = viewModel.termPoliciesURL
        webView.delegate = self
        webView.backgroundColor = .white
        webView.loadRequest(URLRequest(url: url))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        } else { // Sent from unauthenticated user experience
            view.backgroundColor = .primaryColor // Required for nav bar background
            
            let titleDict: [String: Any] = [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: OpenSans.bold.of(size: 18)
            ]
            navigationController?.navigationBar.titleTextAttributes = titleDict
        }
    }
    
    // Prevents status bar color flash when pushed from MoreViewController
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        dLog()
    }
}

extension TermsPoliciesViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
    
}
