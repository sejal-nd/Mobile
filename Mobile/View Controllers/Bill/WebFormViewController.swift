//
//  WebFormViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 11/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

protocol WebFormViewControllerDelegate: class {
    func webFormViewController(_ viewController: WebFormViewController, didRedirectToUrl url: URL)
}

class WebFormViewController: UIViewController {
    
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration()).usingAutoLayout()
    let errorLabel = UILabel(frame: .zero).usingAutoLayout()
    
    private var urlString: String {
        switch Environment.shared.opco {
        case .bge:
            return "https://bge-sit-620.paymentus.io/xotp/pm/bge"
        case .comEd:
            return "https://comd-sit-623.paymentus.io/xotp/pm/comd"
        case .peco:
            return "https://peco-sit-622.paymentus.io/xotp/pm/peco"
        }
    }
    private let postbackUrl = "https://whateverwewant.com"
    
    weak var delegate: WebFormViewControllerDelegate?
    let bankOrCard: BankOrCard!
    var walletItemId: String? = nil // Setting this will load the edit iFrame rather than add
    
    let disposeBag = DisposeBag()
    
    init(bankOrCard: BankOrCard, walletItemId: String? = nil) {
        self.bankOrCard = bankOrCard
        self.walletItemId = walletItemId
        
        super.init(nibName: nil, bundle: nil)
        
        if self.bankOrCard == .bank {
            title = NSLocalizedString("Add Bank Account", comment: "")
        } else {
            title = NSLocalizedString("Add Card", comment: "")
        }

        fetchEncryptionKey()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        view.addSubview(errorLabel)
        errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 29).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -29).isActive = true
        errorLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setColoredNavBar()
    }
    
    func showError() {
        loadingIndicator.isHidden = true
        errorLabel.isHidden = false
    }
    
    func fetchEncryptionKey() {
        let walletService = ServiceFactory.createWalletService()
        walletService.fetchWalletEncryptionKey(customerId: AccountsStore.shared.customerIdentifier,
                                               bankOrCard: self.bankOrCard,
                                               postbackUrl: self.postbackUrl,
                                               walletItemId: self.walletItemId)
            .subscribe(onNext: { [weak self] key in
                guard let self = self else { return }
                print(key)
                
                var urlComponents = URLComponents(string: self.urlString)
                urlComponents?.queryItems = [
                    URLQueryItem(name: "authToken", value: key)
                ]
                if let components = urlComponents, let url = components.url {
                    let request = URLRequest(url: url)
                    self.webView.load(request)
                } else {
                    self.showError()
                }
            }, onError: { [weak self] err in
                self?.showError()
            }).disposed(by: disposeBag)
    }

}

extension WebFormViewController: WKNavigationDelegate {
    
    /// One of these two methods will catch the postback.
    /// We might want to remove one when we figure out which it will be.
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url, url.absoluteString.starts(with: postbackUrl) {
            delegate?.webFormViewController(self, didRedirectToUrl: url)
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = webView.url, url.absoluteString.starts(with: postbackUrl) {
            decisionHandler(.cancel)
            delegate?.webFormViewController(self, didRedirectToUrl: url)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        loadingIndicator.isHidden = true
    }
}
