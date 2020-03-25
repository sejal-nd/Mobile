//
//  SERWebView.swift
//  BGE
//
//  Created by Cody Dillon on 3/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import WebKit
import RxSwift

class SERWebViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    let accountService = ServiceFactory.createAccountService()
    
    var accountDetail: AccountDetail!
    
    var viewModel: SERWebViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SERWebViewModel(accountService: accountService, accountDetail: accountDetail)
        
        title = NSLocalizedString("Smart Energy Rewards", comment: "")
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onInfoButtonPress))
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = NSLocalizedString("Tooltip", comment: "")
        navigationItem.rightBarButtonItem = infoButton
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        viewModel.fetchSSOData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] ssoData in
                
                guard let self = self else {
                    return
                }
                
                let js = self.viewModel.getWidgetJs(ssoData: ssoData)
                
                self.webView.evaluateJavaScript(js, completionHandler: { (resp, err) in
                    if err != nil {
                        self.errorLabel.isHidden = false
                    } else {
                        self.webView.isHidden = false
                    }
                })
                }, onError: { [weak self] err in
                    self?.errorLabel.isHidden = false
                }, onCompleted: { [weak self] in
                    self?.loadingIndicator.isHidden = true
            }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func onInfoButtonPress() {
        let alertVc = UIAlertController(title: NSLocalizedString("Billing Period Info", comment: ""),
                                        message: NSLocalizedString("The dates shown represent your billing period. Smart meter data is typically available within 24-48 hours of your usage.", comment: ""),
                                        preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alertVc, animated: true, completion: nil)
    }
}

extension SERWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.loadingIndicator.isHidden = true
        self.errorLabel.isHidden = false
    }
}

extension SERWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.loadingIndicator.isHidden = true
        self.errorLabel.isHidden = false
    }
}
