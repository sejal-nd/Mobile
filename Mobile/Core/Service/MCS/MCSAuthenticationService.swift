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
    
    #if os(iOS)
    // MCS Login Implementation
    // Steps:
    //  1. Retreive token from Layer 7 API gateway
    //  2. Exchange the token
    //  3. Fetch the list of accounts for the user
    func login(username: String, password: String, stayLoggedIn: Bool) -> Observable<ProfileStatus> {
        // 1
        return fetchAuthToken(username: username, password: password)
            // 2
            .flatMap { tokenResponse in
                MCSApi.shared.exchangeToken(tokenResponse.token, storeToken: stayLoggedIn)
                    .mapTo(tokenResponse.profileStatus)
            }
            .do(onNext: { _ in
                UserDefaults.standard.set(stayLoggedIn, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
                
                // Clear quick actions on sign in, removing "Report Outage." It'll be re-added after
                // loading account details on the home screen if the user has only 1 account
                RxNotifications.shared.configureQuickActions.onNext(true)
            })
            
            // 3
            .flatMap { profileStatus in
                // This will error if the first account is password protected
                MCSAccountService().fetchAccounts().mapTo(profileStatus)
            }
            .do(onNext: { _ in
                // Reconfigure quick actions since we now know whether or not the user is multi-account.
                RxNotifications.shared.configureQuickActions.onNext(true)
            },
                onError: { _ in  self.logout() }
            )
    }
    
    func validateLogin(username: String, password: String) -> Observable<Void> {
        return fetchAuthToken(username: username, password: password)
            .mapTo(())
    }
    #endif
    
    func isAuthenticated() -> Bool {
        return MCSApi.shared.isAuthenticated()
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
        let postDataLoggingStr = "username=\(Environment.shared.opco.rawValue.uppercased())\\\(username)&password=******"
        let method = HttpMethod.post
        let path = Environment.shared.mcsConfig.oAuthEndpoint
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = postDataString.data(using: .utf8)
        
        let requestId = ShortUUIDGenerator.getUUID(length: 8)
        APILog(MCSAuthenticationService.self, requestId: requestId, path: path, method: method, logType: .request, message: postDataLoggingStr)
        
        return URLSession.shared.rx.dataResponse(request: request, onCanceled: {
            APILog(MCSAuthenticationService.self, requestId: requestId, path: path, method: method, logType: .canceled, message: nil)
        })
            .do(onError: { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                APILog(MCSAuthenticationService.self, requestId: requestId, path: path, method: method, logType: .error, message: serviceError.errorDescription)
            })
            .map { data in
                switch AuthTokenParser.parseAuthTokenResponse(data: data) {
                case .success(let response):
                    APILog(MCSAuthenticationService.self, requestId: requestId, path: path, method: method, logType: .response, message: String(data: data, encoding: .utf8))
                    return response
                case .failure(let error):
                    APILog(MCSAuthenticationService.self, requestId: requestId, path: path, method: method, logType: .error, message: String(data: data, encoding: .utf8))
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
        StormModeStatus.shared.isOn = false
    }
    
    func getMaintenanceMode(postNotification: Bool) -> Observable<Maintenance> {
        return MCSApi.shared.get(pathPrefix: .anon, path: "config/maintenance")
            .map { json in
                let maint = Maintenance.from(json as! NSDictionary)!
                if maint.allStatus && postNotification {
                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: self)
                }
                return maint
            }
    }
    
    func getMinimumVersion() -> Observable<MinimumVersion> {
        return MCSApi.shared.get(pathPrefix: .anon, path: "config/versions")
            .map { json in
                MinimumVersion.from(json as! NSDictionary)!
        }
    }
    
    #if os(iOS)
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [ChangePasswordParams.oldPassword.rawValue: currentPassword,
                      ChangePasswordParams.newPassword.rawValue: newPassword]
        
        return MCSApi.shared.put(pathPrefix: .auth, path: "profile/password", params: params)
            .mapTo(())
    }
    
    func changePasswordAnon(username: String, currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [AnonChangePasswordParams.username.rawValue: username,
                      AnonChangePasswordParams.oldPassword.rawValue: currentPassword,
                      AnonChangePasswordParams.newPassword.rawValue: newPassword]
        
        return MCSApi.shared.put(pathPrefix: .anon, path: "profile/password", params: params)
            .mapTo(())
    }
    #endif
    
    
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
        var params = ["phone": phone]
        if let id = identifier {
            params["identifier"] = id
        }
        
        if let accNum = accountNumber {
            params["account_number"] = accNum
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "recover/username", params: params)
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
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "recover/username", params: params)
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
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "account/lookup", params: params)
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
    
    #if os(iOS)
    func recoverPassword(username: String) -> Observable<Void> {
        let params = ["username" : username]
        return MCSApi.shared.post(pathPrefix: .anon, path: "recover/password", params: params)
            .mapTo(())
    }
    #endif

}
