//
//  PKCEAuthenticationService.swift
//  Mobile
//
//  Created by Vishnu Nair on 08/12/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import AuthenticationServices
import CommonCrypto

class PKCEAuthenticationService: UIViewController {
    static let `default` = PKCEAuthenticationService()
    
    var authSession: ASWebAuthenticationSession!
    
    func presentLoginForm(completion: @escaping (Result<PKCEResult, Error>) -> ()) {
        let codeVerifier = createCodeVerifier()
        let codeChallenge = createCodeChallenge(for: codeVerifier)
        let codeChallengeMethod = "S256"
        let urlString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=\(Configuration.shared.b2cPolicy)&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=\(Configuration.shared.b2cRedirectURI)://auth&scope=openid%20offline_access&response_type=code&code_challenge=\(codeChallenge)&code_challenge_method=\(codeChallengeMethod)&prompt=login#"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                Log.error("ASWebAuthentication Session failed/terminated")
                completion(.failure(error!))
                return
            }
            
            Log.info("ASWebAuthentication Success Callback URL: \(successURL.absoluteString)")
            
            if let authorizationCode = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "code"}).first {
                AuthenticationService.loginWithCode(code: authorizationCode.value ?? "nil",
                                                    codeVerifier: codeVerifier) { result in
                                            switch result {
                                            case .success(let tokenResponse):
                                                Log.info("user has logged in succesfully")
                                                completion(.success(PKCEResult(tokenResponse: tokenResponse)))
                                            case .failure(let error):
                                                Log.error("login error \(error.description)")
                                                completion(.failure(error))
                                            }
                }
            } else if let redirect_policy = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "redirect"}).first {
                completion(.success(PKCEResult(redirect: redirect_policy.value)))
            } else {
                completion(.failure(NetworkingError.unknown))
            }
        })
        
        authSession.presentationContextProvider = self
        authSession.start()
    }
    
    func presentMySecurityForm(completion: @escaping (Result<String, Error>) -> ()) {
        let urlString = "https://\(Configuration.shared.b2cAuthEndpoint)/\(Configuration.shared.b2cTenant).onmicrosoft.com/oauth2/v2.0/authorize?p=B2C_1A_PROFILEEDIT_MOBILE&client_id=\(Configuration.shared.b2cClientID)&nonce=defaultNonce&redirect_uri=\(Configuration.shared.b2cRedirectURI)://auth&scope=openid%20offline_access&response_type=id_token"
        
        guard let url = URL(string: urlString) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                Log.error("ASWebAuthentication Session failed/terminated")
                completion(.failure(error!))
                return
            }
            
            let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.fragment?.components(separatedBy: "id_token=").get(at: 1)
            Log.info("ASWebAuthentication Success Callback URL: \(successURL.absoluteString)")
            completion(.success(oauthToken ?? ""))
        })
        
        authSession.presentationContextProvider = self
        authSession.start()
    }
    
    func presentAssistanceCTA(ctaURL: String, completion: @escaping (Result<String, Error>) -> ()) {

        guard let url = URL(string: ctaURL) else { return }
        
        let callbackScheme = Configuration.shared.b2cRedirectURI
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme, completionHandler: { (callbackURL, error) in
            guard error == nil, let successURL = callbackURL else {
                Log.error("ASWebAuthentication Session failed/terminated")
                completion(.failure(error!))
                return
            }
            
            let oauthToken = NSURLComponents(string: (successURL.absoluteString))?.fragment?.components(separatedBy: "id_token=").get(at: 1)
            Log.info("ASWebAuthentication Success Callback URL: \(successURL.absoluteString)")
            completion(.success(oauthToken ?? ""))
        })
        
        authSession.presentationContextProvider = self
        authSession.start()
    }
    
    // https://docs.microsoft.com/en-us/azure/active-directory-b2c/authorization-code-flow
    // https://auth0.com/docs/get-started/authentication-and-authorization-flow/call-your-api-using-the-authorization-code-flow-with-pkce#authorize-user
    private func createCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func createCodeChallenge(for verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var buffer = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &buffer)
        }
        let hash = Data(buffer)
        return hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

extension PKCEAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        self.view.window ?? ASPresentationAnchor()
    }
}
