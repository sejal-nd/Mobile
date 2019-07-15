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
    
    @IBOutlet weak var webView: WKWebView!
    
    private let viewModel = TermsPoliciesViewModel()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Policies and Terms", comment: "")
        
        let request = URLRequest(url: viewModel.termPoliciesURL)
        webView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}
