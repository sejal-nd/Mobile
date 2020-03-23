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
    
    var accountDetail: AccountDetail! // Passed from SERPTSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
//        GoogleAnalytics.log(event: .viewUsageOfferComplete,
//                             dimensions: [.residentialAMI: residentialAMIString])
        
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
        
        if let premiseNum = accountDetail.premiseNumber {
            accountService.fetchSSOData(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNum)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] ssoData in
                    if let html = self?.htmlForWidget(with: ssoData) {
                        self?.webView.loadHTMLString(html, baseURL: nil)
                    }
                    else {
                        self?.errorLabel.isHidden = false
                    }
                }, onError: { [weak self] err in
                    self?.loadingIndicator.isHidden = true
                    self?.errorLabel.isHidden = false
                }).disposed(by: disposeBag)
        }
    }
    
    private func htmlForWidget(with ssoData: SSOData) -> String {
        let url = Bundle.main.url(forResource: "PTRWidget", withExtension: "html")!
        let src = String(format: "https://ei-bgec-stage.opower.com/ei/x/e/peak-time-rebate.js?utilityCustomerId=%@", ssoData.utilityCustomerId)
        return try! String(contentsOf: url)
            .replacingOccurrences(of: "[widgetJsSrc]", with: src)
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
