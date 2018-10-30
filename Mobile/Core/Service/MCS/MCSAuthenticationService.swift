//
//  MCSAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

private enum OAuthQueryParams: String {
    case username = "username"
    case password = "password"
    case encode = "encode"
}

private enum ChangePasswordParams: String {
    case oldPassword = "old_password"
    case newPassword = "new_password"
}

private enum AnonChangePasswordParams: String {
    case username = "username"
    case oldPassword = "old_password"
    case newPassword = "new_password"
}

fileprivate extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}

struct MCSAuthenticationService : AuthenticationService {
    
    // MCS Login Implementation
    // Steps:
    //  1. Retreive token from Layer 7 API gateway
    //  2. Exchange the token
    //  3. Fetch the list of accounts for the user
    //  4. Fetch the account detail for the first account
    //  5. If not password protected account - success
    func login(username: String, password: String, stayLoggedIn: Bool) -> Observable<(ProfileStatus, AccountDetail)> {
        // 1
        return fetchAuthToken(username: username, password: password)
            
            // 2
            .flatMap { tokenResponse in
                MCSApi.shared.exchangeToken(tokenResponse.token, storeToken: stayLoggedIn)
                    .map { tokenResponse }
            }
            .do(onNext: { _ in
                UserDefaults.standard.set(stayLoggedIn, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
                
                // Clear quick actions on sign in, removing "Report Outage." It'll be re-added after
                // loading account details on the home screen if the user has only 1 account
                RxNotifications.shared.configureQuickActions.onNext(true)
            })
            
            // 3
            .flatMap { tokenResponse in
                MCSAccountService().fetchAccounts()
                    .map { ($0, tokenResponse)}
            }
            .do(onNext: { _ in
                // Reconfigure quick actions since we now know whether or not the user is multi-account.
                RxNotifications.shared.configureQuickActions.onNext(true)
            },
                onError: { _ in  self.logout() }
            )
            
            // 4
            .flatMap { (accounts, tokenResponse) in
                MCSAccountService().fetchAccountDetail(account: accounts[0])
                    .map { ($0, tokenResponse) }
            }
            .map { (accountDetail, tokenResponse) in
                // 5
                if accountDetail.isPasswordProtected {
                    self.logout()
                    throw ServiceError(serviceCode: ServiceErrorCode.fnAccountProtected.rawValue)
                } else {
                    return (tokenResponse.profileStatus, accountDetail)
                }
            }
            .do(onError: { _ in self.logout() })
    }
    
    func validateLogin(username: String, password: String) -> Observable<Void> {
        return fetchAuthToken(username: username, password: password)
            .mapTo(())
    }
    
    func isAuthenticated() -> Bool {
        return MCSApi.shared.isAuthenticated();
    }

    /// Fetch the authorization token for the given credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    private func fetchAuthToken(username: String, password: String) -> Observable<AuthTokenResponse> {
        guard let username = username.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
            let password = password.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) else {
                return .error(ServiceError(serviceCode: "FN-FAIL-LOGIN"))
        }
        
        let postDataString = "username=\(Environment.shared.opco.rawValue.uppercased())\\\(username)&password=\(password)"
        let method = HttpMethod.post
        var request = URLRequest(url: URL(string: Environment.shared.oAuthEndpoint)!)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = postDataString.data(using: .utf8)
        
        let requestId = ShortUUIDGenerator.getUUID(length: 8)
        APILog(requestId: requestId, method: method, message: "REQUEST - BODY: \(postDataString)")
        
        return URLSession.shared.rx.dataResponse(request: request)
            .do(onNext: { data in
                let resBodyString = String(data: data, encoding: .utf8) ?? "No Response Data"
                APILog(requestId: requestId, method: method, message: "RESPONSE - BODY: \(resBodyString)")
            }, onError: { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                APILog(requestId: requestId, method: method, message: "ERROR - \(serviceError.errorDescription ?? "")")
            })
            .map { data in
                switch AuthTokenParser.parseAuthTokenResponse(data: data) {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }
            .catchError {
                throw ServiceError(cause: $0)
        }
    }
    
    func logout() {
        MCSApi.shared.logout()
        AccountsStore.shared.accounts = nil
        AccountsStore.shared.currentAccount = nil
        AccountsStore.shared.customerIdentifier = nil
    }
    
    func getMaintenanceMode() -> Observable<Maintenance> {
        let opco = Environment.shared.opco.displayString.uppercased()
        
        return MCSApi.shared.get(path: "anon_\(MCSApi.API_VERSION)/" + opco + "/config/maintenance")
            .map { json in
                Maintenance.from(json as! NSDictionary)!
        }
    }
    
    func getMinimumVersion() -> Observable<MinimumVersion> {
        let opco = Environment.shared.opco.displayString.uppercased()
        
        return MCSApi.shared.get(path: "anon_\(MCSApi.API_VERSION)/" + opco + "/config/versions")
            .map { json in
                MinimumVersion.from(json as! NSDictionary)!
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [ChangePasswordParams.oldPassword.rawValue: currentPassword,
                      ChangePasswordParams.newPassword.rawValue: newPassword]
        
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/profile/password", params: params)
            .mapTo(())
    }
    
    func changePasswordAnon(username: String, currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [AnonChangePasswordParams.username.rawValue: username,
                      AnonChangePasswordParams.oldPassword.rawValue: currentPassword,
                      AnonChangePasswordParams.newPassword.rawValue: newPassword]
        
        let opco = Environment.shared.opco.displayString.uppercased()

        
        let path = "anon_\(MCSApi.API_VERSION)/" + opco + "/profile/password"
        
        return MCSApi.shared.put(path: path, params: params)
            .mapTo(())
    }
    
    
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
        var params = ["phone": phone]
        if let id = identifier {
            params["identifier"] = id
        }
        
        if let accNum = accountNumber {
            params["account_number"] = accNum
        }
        
        let opco = Environment.shared.opco.displayString.uppercased()
        let path = "anon_\(MCSApi.API_VERSION)/" + opco + "/recover/username"
        
        return MCSApi.shared.post(path: path, params: params)
            .map { json in
                guard let maskedEntries = json as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return maskedEntries.compactMap(ForgotUsernameMasked.from)
        }
    }
    
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String> {
        var params = ["phone": phone,
                      "question_id": questionId,
                      "security_answer": questionResponse,
                      "cipherString": cipher] as [String : Any]
        
        if let id = identifier {
            params["identifier"] = id
        }
        
        if let accNum = accountNumber {
            params["account_number"] = accNum
        }
        
        let opco = Environment.shared.opco.displayString.uppercased()
        let path = "anon_\(MCSApi.API_VERSION)/" + opco + "/recover/username"
        
        return MCSApi.shared.post(path: path, params: params)
            .map { data in
                guard let unmasked = data as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue,
                                       serviceMessage: "Unable to parse response")
                }
                
                return unmasked
        }
    }
    
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]> {
        //let params = ["AccountDetails": ["SocialSecurityOrTaxId" : identifier, "PhoneNumber" : phone]] // MMS - Kenny added this, I don't know where it comes from. It's not in the API documentation and the call fails unless the params are as follows:
        let params: [String: Any] = ["identifier": identifier, "phone": phone]
    
        let opco = Environment.shared.opco.displayString.uppercased()
        let path = "anon_\(MCSApi.API_VERSION)/" + opco + "/account/lookup"
        
        return MCSApi.shared.post(path: path, params: params)
            .map { json in
                guard let entries = json as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue,
                                       serviceMessage: "Unable to parse response")
                }
                
                return entries
                    .compactMap { $0["AccountDetails"] as? NSDictionary }
                    .compactMap(AccountLookupResult.from)
        }
    }
    
    func recoverPassword(username: String) -> Observable<Void> {
        let params = ["username" : username]
        let opco = Environment.shared.opco.displayString.uppercased()
        let path = "anon_\(MCSApi.API_VERSION)/" + opco + "/recover/password"
        
        return MCSApi.shared.post(path: path, params: params)
            .mapTo(())
    }

}

fileprivate func APILog(requestId: String, method: HttpMethod, message: String) {
    #if DEBUG
        NSLog("[OAuthApi][%@] %@ %@", requestId, method.rawValue, message)
    #endif
}