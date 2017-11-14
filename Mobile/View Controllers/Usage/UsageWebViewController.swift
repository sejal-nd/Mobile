//
//  UsageWebViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import WebKit
import RxSwift

class UsageWebViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    let accountService = ServiceFactory.createAccountService()
    
    var accountDetail: AccountDetail! // Passed from UsageViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Usage Details", comment: "")
        
        view.insertSubview(webView, belowSubview: loadingIndicator)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        if let premiseNum = accountDetail.premiseNumber {
            accountService.fetchSSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] ssoData in
                    let js = "var data={SAMLResponse:'\(ssoData.samlResponse)',RelayState:'\(ssoData.relayState.absoluteString)'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','\(ssoData.ssoPostURL.absoluteString)');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"
                    self?.webView.evaluateJavaScript(js, completionHandler: { (resp, err) in
                        if err != nil {
                            self?.loadingIndicator.isHidden = true
                            self?.errorLabel.isHidden = false
                        } else {
                            self?.webView.isHidden = false
                        }
                    })
                }, onError: { [weak self] err in
                    self?.loadingIndicator.isHidden = true
                    self?.errorLabel.isHidden = false
                }).disposed(by: disposeBag)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
}

extension UsageWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
    }
}