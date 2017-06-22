//
//  WebViewController.swift
//  Mobile
//
//  Created by Sam Francis on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WebViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    private var navTitle: String
    private var url: URL
    
    
    init(title: String, url: URL) {
        navTitle = title
        self.url = url
        
        super.init(nibName: WebViewController.className, bundle: nil)
        
        modalPresentationStyle = .formSheet // For iPad
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        navBarView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        titleLabel.textColor = .blackText
        titleLabel.text = navTitle
        
        webView.delegate = self
        webView.loadRequest(URLRequest(url: url))
    }
    
    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension WebViewController: UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loadingIndicator.isHidden = true
    }
    
}
