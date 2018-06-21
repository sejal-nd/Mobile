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
    
    @IBOutlet weak var webContainerView: UIView!
    private var webView: WKWebView!
    
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
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
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
    
    
    // MARK: - Helper
    
    private func setupWKWebView(with url: URL) {
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
    
    // Prevents status bar color flash when pushed from MoreViewController
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
