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
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var webView: WKWebView!
    
    private var url: URL
    
    init(title: String, url: URL) {
        self.url = url
        
        super.init(nibName: WebViewController.className, bundle: nil)
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        
        addCloseButton()

        webView.navigationDelegate = self
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
    }
    
}
