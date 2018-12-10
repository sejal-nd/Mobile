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

// Default implementation to make these protocol functions optional
extension PaymentusFormViewControllerDelegate {
    func didEditWalletItem() { }
}

class PaymentusFormViewController: UIViewController {
    
    let TIMEOUT: TimeInterval = 1800 // 30 minutes
    
    var webView: WKWebView!
    let loadingIndicator = LoadingIndicator().usingAutoLayout()
    let errorLabel = UILabel(frame: .zero).usingAutoLayout()
    
    weak var delegate: PaymentusFormViewControllerDelegate?
    let bankOrCard: BankOrCard
    let walletItemId: String? // Setting this will load the edit iFrame rather than add
    let temporary: Bool // If true, load the iFrame that doesn't save to the wallet
    
    let disposeBag = DisposeBag()
    
    var editingDefaultItem = false // We need to know if user is editing the default so we can properly fire the `defaultWalletItemUpdated` notification
    var shouldPopToMakePaymentOnSave = false
    var shouldPopToRootOnSave = false
    
    init(bankOrCard: BankOrCard, temporary: Bool, walletItemId: String? = nil) {
        self.bankOrCard = bankOrCard
        self.temporary = temporary
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
        
        // Start the timer. The Paymentus session is only valid for [TIMEOUT] seconds - so if that elapses,
        // alert the user and reload the page
        Timer.scheduledTimer(withTimeInterval: TIMEOUT, repeats: false) { [weak self] timer in
            let alert = UIAlertController(title: NSLocalizedString("Your session has timed out due to inactivity.", comment: ""),
                                          message: NSLocalizedString("Your payment method has not been saved. Sorry for the inconvenience. Please re-enter your payment information.", comment: ""),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] _ in
                self?.showLoadingState()
                self?.webView.resignFirstResponder() // Dismissing the keyboard resolves some jankiness
                self?.fetchEncryptionKey()
            }))
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    func fetchEncryptionKey() {
        let walletService = ServiceFactory.createWalletService()
        walletService.fetchWalletEncryptionKey(customerId: AccountsStore.shared.customerIdentifier,
                                               bankOrCard: bankOrCard,
                                               temporary: temporary,
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
        if let bodyString = message.body as? String {
            if bodyString.contains("frameHeight") { return } // Ignore the frameHeight message
            
            if let data = bodyString.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! String {
                let pmDetailsString = json.replacingOccurrences(of: "pmDetails:", with: "")
                if let pmDetailsData = pmDetailsString.data(using: .utf8), let pmDetailsJson = try? JSONSerialization.jsonObject(with: pmDetailsData, options: []) as! [String: Any] {
                    // Payment method was successfully submitted
                    
                    var didSetDefault = false
                    if let defaultStr = pmDetailsJson["Default"] as? String, defaultStr == "true" {
                        didSetDefault = true
                    }
                    
                    var nickname: String?
                    if temporary {
                        nickname = NSLocalizedString("Not saved to My Wallet", comment: "")
                    } else {
                        nickname = pmDetailsJson["ProfileDescription"] as? String
                    }
                    
                    let walletItem = WalletItem(walletItemID: pmDetailsJson["Token"] as? String, maskedWalletItemAccountNumber: pmDetailsJson["MaskedAccountNumber"] as? String, nickName: nickname, isDefault: didSetDefault, bankOrCard: bankOrCard)
                    
                    if walletItemId != nil {
                        delegate?.didEditWalletItem()
                    } else {
                        switch bankOrCard {
                        case .bank:
                            delegate?.didAddBank(walletItem)
                        case .card:
                            delegate?.didAddCard(walletItem)
                        }
                    }
                    
                    if editingDefaultItem || didSetDefault {
                        RxNotifications.shared.defaultWalletItemUpdated.onNext(())
                    }
                    
                    if shouldPopToRootOnSave {
                        navigationController?.popToRootViewController(animated: true)
                    } else if shouldPopToMakePaymentOnSave {
                        for vc in navigationController!.viewControllers {
                            guard let dest = vc as? MakePaymentViewController else {
                                continue
                            }
                            navigationController?.popToViewController(dest, animated: true)
                        }
                    } else {
                        navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

extension PaymentusFormViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, !url.absoluteString.starts(with: Environment.shared.paymentusUrl) {
            showLoadingState()
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWebView()
    }
    
}
