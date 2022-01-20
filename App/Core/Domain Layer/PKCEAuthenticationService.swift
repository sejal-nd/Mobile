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
    
    func presentLoginForm(completion: @escaping (Bool, String) -> ()) {
        let urlString = "https://\(Configuration.shared.b2cTenant).b2clogin.com/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=\(Configuration.shared.b2cPolicy)&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=\(Configuration.shared.b2cRedirectURI)://auth&scope=openid%20offline_access&response_type=code&prompt=login#"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                Log.error("ASWebAuthentication Session failed/terminated")
                completion(false, "nil")
                return
            }
            
            
            Log.info(successURL.absoluteString)
            
            if let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "code"}).first {
                AuthenticationService.loginWithCode(code: oauthToken.value ?? "nil") { [weak self] (result: Result<Bool, NetworkingError>) in
                                            switch result {
                                            case .success(let hasTempPassword):
                                                Log.info("user has logged in succesfully")
                                                completion(true, "nil")
                                            case .failure(let error):
                                                Log.error("login error \(error.description)")
                                                completion(false, error.description)
                                            }
                }
            } else if let redirect_policy = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "redirect"}).first{
                completion(false, redirect_policy.value ?? "nil")
            } else {
                completion(false, "nil")
            }
        })
        
        authSession.presentationContextProvider = self
        authSession.start()
        
        
    }
    
    func presentMySecurityForm(completion: @escaping (Bool, String) -> ()){
        let urlString = "https://\(Configuration.shared.b2cTenant).b2clogin.com/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_PROFILEEDIT_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=\(Configuration.shared.b2cRedirectURI)://auth&scope=openid%20offline_access&response_type=id_token"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                Log.error("ASWebAuthentication Session failed/terminated")
                completion(false, error?.localizedDescription ?? "nil")
                return
            }
            
            let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.fragment?.components(separatedBy: "id_token=").get(at: 1)
            Log.info(successURL.absoluteString)
            completion(true, oauthToken ?? "nil")
            
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
