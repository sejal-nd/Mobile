//
//  PKCEAuthenticationService.swift
//  Mobile
//
//  Created by Vishnu Nair on 08/12/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import AuthenticationServices

class PKCEAuthenticationService:UIViewController {
    static let sharedService = PKCEAuthenticationService()
    
    var authSession: ASWebAuthenticationSession!
    
    func presentLoginForm(completion: @escaping (Bool) -> ()){
        let urlString = "https://euazurephitest.b2clogin.com/euazurephitest.onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_SIGNIN_MOBILE&client_id=733a9d3b-9769-4ef3-8444-34128c5d0d63&nonce=defaultNonce&redirect_uri=msauth.com.exelon.mobile.pepco.testing%3A%2F%2Fauth&scope=openid%20offline_access&response_type=code&prompt=login#"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = "msauth.com.exelon.mobile.pepco.testing"
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                print("Nothing")
                return
            }
            
            let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "code"}).first
            
            print(successURL.absoluteString)
            print("AuthCode is \((oauthToken as? NSString)?.components(separatedBy: "=")[1])")
            
            AuthenticationService.loginWithCode(code: oauthToken?.value ?? "nil"){ [weak self] (result: Result<Bool, NetworkingError>) in
                                        switch result {
                                        case .success(let hasTempPassword):
                                            print("loggedin")
                                            completion(true)
                                        case .failure(let error):
                                            print("failed")
                                        }
            }
        })
        
        authSession.presentationContextProvider = self
        authSession.start()
        
        
    }
    
}

extension PKCEAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        self.view.window ?? ASPresentationAnchor()
    }
}
