//
//  PaymentusFormViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 11/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit
import RxSwift

protocol PaymentusFormViewControllerDelegate: class {
    func didEditWalletItem()
    func didAddCard(_ walletItem: WalletItem?)
    func didAddBank(_ walletItem: WalletItem?)
}

class PaymentusFormViewController: UIViewController {
    
    var webView: WKWebView!
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    let errorLabel = UILabel(frame: .zero).usingAutoLayout()
    
    private let postbackUrl = "https://mindgrub.com/"
    
    weak var delegate: PaymentusFormViewControllerDelegate?
    let bankOrCard: BankOrCard
    let walletItemId: String? // Setting this will load the edit iFrame rather than add
    
    let disposeBag = DisposeBag()
    
    var shouldPopToRootOnSave = false
    
    init(bankOrCard: BankOrCard, walletItemId: String? = nil) {
        self.bankOrCard = bankOrCard
        self.walletItemId = walletItemId
        
        super.init(nibName: nil, bundle: nil)
        
        if self.bankOrCard == .bank {
            title = walletItemId != nil ? NSLocalizedString("Edit Bank Account", comment: "") : NSLocalizedString("Add Bank Account", comment: "")
        } else {
            title = walletItemId != nil ? NSLocalizedString("Edit Card", comment: "") : NSLocalizedString("Add Card", comment: "")
        }

        fetchEncryptionKey()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .white
        
        let contentController = WKUserContentController()
        let source = "window.addEventListener('message', function(event){ window.webkit.messageHandlers.iosListener.postMessage(JSON.stringify(event.data)); })"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
        contentController.add(self, name: "iosListener")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config).usingAutoLayout()
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
        webView.isHidden = true
        errorLabel.isHidden = false
    }
    
    func showLoadingState() {
        loadingIndicator.isHidden = false
        webView.isHidden = true
        errorLabel.isHidden = true
    }
    
    func showWebView() {
        loadingIndicator.isHidden = true
        webView.isHidden = false
        errorLabel.isHidden = true
    }
    
    func fetchEncryptionKey() {
        let walletService = ServiceFactory.createWalletService()
        walletService.fetchWalletEncryptionKey(customerId: AccountsStore.shared.customerIdentifier,
                                               bankOrCard: bankOrCard,
                                               postbackUrl: postbackUrl,
                                               walletItemId: walletItemId)
            .subscribe(onNext: { [weak self] key in
                guard let self = self else { return }

                var urlComponents = URLComponents(string: Environment.shared.paymentusUrl)
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

extension PaymentusFormViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received postMessage: \(message.body)")
    }
}

extension PaymentusFormViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if url.absoluteString.starts(with: postbackUrl) {
            decisionHandler(.cancel)
            
            // parse wallet item from request
            
            if walletItemId != nil {
                delegate?.didEditWalletItem()
            } else {
                switch bankOrCard {
                case .bank:
                    delegate?.didAddBank(nil)
                case .card:
                    delegate?.didAddCard(nil)
                }
            }
            
            // If we can know the `isDefault` status here, we can be smarter about firing this notification.
            RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            
            if shouldPopToRootOnSave {
                navigationController?.popToRootViewController(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        } else if !url.absoluteString.starts(with: Environment.shared.paymentusUrl) {
            showLoadingState()
            decisionHandler(.allow)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWebView()
    }
    
}
