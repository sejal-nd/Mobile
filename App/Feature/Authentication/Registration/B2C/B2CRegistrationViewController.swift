//
//  B2CRegistrationViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/5/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import WebKit

class B2CRegistrationViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var errorTitle: UILabel!
    @IBOutlet weak var errorDescription: UILabel!
    
    weak var delegate: RegistrationViewControllerDelegate?
    
    var validatedAccount: ValidatedAccountResponse?
    var selectedAccount: AccountResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        addCloseButton()
        
        webView.navigationDelegate = self
        webView.isHidden = true
        
        errorImage.tintColor = .attentionOrange
        errorTitle.font = SystemFont.semibold.of(textStyle: .title3)
        errorTitle.textColor = .deepGray
        errorDescription.font = SystemFont.regular.of(textStyle: .footnote)
        errorDescription.textColor = .deepGray
        errorView.isHidden = true
        
        fetchJWT()
    }
    
    private func fetchJWT() {
        var index = 0
        if let selectedAccount = selectedAccount {
            index = validatedAccount?.accounts.firstIndex { $0.accountNumber == selectedAccount.accountNumber } ?? 0
        }
        
        let request = B2CJWTRequest(customerID: validatedAccount?.accounts[index].customerID ?? "", type: validatedAccount?.type?[index] ?? "residential", lastname: validatedAccount?.customerName)
        RegistrationService.fetchB2CJWT(request: request) { [weak self] result in
            switch result {
            case .success(let token):
                guard let self = self else { return }
                self.errorView.isHidden = true
                
                self.loadWebView(token: token)
            case .failure:
                guard let self = self else { return }
                self.errorView.isHidden = false
                self.loadingIndicator.isHidden = true
            }
        }
    }
    
    private func loadWebView(token: String) {
        let registrationURLString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_REGISTER_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=https%3A%2F%2Fjwt.ms&scope=openid&response_type=id_token&prompt=login&id_token_hint=\(token)"
        if let url = URL(string: registrationURLString) {
            webView.load(NSURLRequest(url: url) as URLRequest)
        }
    }
    
    private func success() {
        FirebaseUtility.logEvent(.register(parameters: [.complete]))
        
        GoogleAnalytics.log(event: .registerAccountComplete)
        
        delegate?.registrationViewControllerDidRegister(self)
        dismiss(animated: true, completion: nil)
    }
}

extension B2CRegistrationViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        Log.info("URL ---> \(webView.url?.absoluteString) \n\n")
        
        if let urlString = webView.url?.absoluteString,
           urlString.contains("selfAsserted-registration-main-ebill-mobile") {
            success()
        } else if let urlString = webView.url?.absoluteString,
                urlString.contains("SelfAsserted/error") {
            self.errorView.isHidden = false
            self.loadingIndicator.isHidden = true
            self.webView.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let urlString = webView.url?.absoluteString else {
            return
        }
        
        if urlString.contains("id_token=") {
            let token = NSURLComponents(string: urlString)?.fragment?.components(separatedBy: "id_token=").get(at: 1) ?? ""
            if let json = TokenResponse.decodeToJson(token: token) {
                let mfaSignupSelection = json["mfaSignupSelection"] as? String
                RxNotifications.shared.mfaBypass.accept(mfaSignupSelection == "Bypass")
            }
            success()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loadingIndicator.isHidden = true
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorView.isHidden = false
        loadingIndicator.isHidden = true
        webView.isHidden = true
    }
}
