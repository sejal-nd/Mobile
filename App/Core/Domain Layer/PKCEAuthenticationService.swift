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
        let urlString = "https://\(Configuration.shared.b2cTenant).b2clogin.com/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=\(Configuration.shared.b2cPolicy)&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=\(Configuration.shared.b2cRedirectURI)://auth&scope=openid%20offline_access&response_type=code&prompt=login#"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                print("Nothing")
                completion(false)
                return
            }
            
            let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "code"}).first
            
            print(successURL.absoluteString)
            
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
