//
//  iTronSmartThermostatViewController.swift
//  EUMobile
//
//  Created by Majumdar, Amit on 28/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

final class iTronSmartThermostatViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet private weak var webView: WKWebView!
    
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet private weak var errorLabel: UILabel!
    
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    
    var accountDetail: AccountDetail!

    private var viewModel: iTronSmartThermostatViewModel!

    private var backButton: UIBarButtonItem?

    
    // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = iTronSmartThermostatViewModel(accountDetail: accountDetail)
        styleView()
        fetchiTronSSOData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
    // Add back Button
    private func addCustomBackButton() {
        backButton = UIBarButtonItem(image: UIImage(named: "ic_back"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(backAction))
        backButton?.accessibilityLabel = NSLocalizedString("Back", comment: "")
        navigationItem.setLeftBarButton(backButton, animated: false)
    }
    
    // MARK: - Action
    @objc func backAction() {
       navigationController?.popViewController(animated: true)
    }
}

// MARK: - iTronSmartThermostatViewController Private Methods
extension iTronSmartThermostatViewController {
    private func styleView() {
        title = NSLocalizedString("Adjust Thermostat", comment: "")
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        addCustomBackButton()
    }
    
    private func fetchiTronSSOData() {
        viewModel.fetchiTronSSOData()
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
                    self?.loadingIndicator.isHidden = true
                }, onCompleted: { [weak self] in
                    self?.loadingIndicator.isHidden = true
            }).disposed(by: disposeBag)
    }
}

// MARK: - WKNavigationDelegate Methods
extension iTronSmartThermostatViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.loadingIndicator.isHidden = true
        self.errorLabel.isHidden = false
        self.webView.isHidden = true
    }
}

// MARK: - WKUIDelegate Methods
extension iTronSmartThermostatViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.loadingIndicator.isHidden = true
        self.errorLabel.isHidden = false
        self.webView.isHidden = true
    }
}
