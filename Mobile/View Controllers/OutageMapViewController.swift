//
//  OutageMapViewController.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class OutageMapViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    let opco = Environment.sharedInstance.opco
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Outage Map", comment: "")
        
        webView.delegate = self
        
        var urlString: String
        
        switch opco {
        case .bge:
            urlString = "http://outagemaptest.comed.com.s3.amazonaws.com/app.html" //TODO: where's the actual bge link?
        case .comEd:
            urlString = "http://outagemaptest.comed.com.s3.amazonaws.com/app.html"
        case .peco:
            fallthrough
        default:
            urlString = "http://s3.amazonaws.com/outagemaptest.peco.com/external/app.html"
        }
        
        let url = URL(string: urlString)!
        
        let request = URLRequest(url: url)
        
        webView.loadRequest(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension OutageMapViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        dLog(message: "web view finished loading")
    }
    
}
