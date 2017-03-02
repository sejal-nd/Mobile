//
//  OMCAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

private enum OAuthQueryParams: String {
    case Username = "username"
    case Password = "password"
    case Encode = "encode"
}

private enum ChangePasswordParams: String {
    case OldPassword = "old_password"
    case NewPassword = "new_password"
}

class OMCAuthenticationService : AuthenticationService {
    
    // OMC Login Implementation
    // Steps:
    //  1. Retreive token from api gateway
    //  2. Exchange the token with the Oracle SDK
    //  3. Fetch the user through the Oracle SDK
    func login(_ username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void) {
        
        //1
        fetchAuthToken(username: username, password: password) { (result: ServiceResult<String>) in
            
            let backend = OMCMobileBackendManager.shared().defaultMobileBackend
            let auth = backend?.authorization
            
            switch(result) {
            case .Success(let token):
                // 2
                auth?.authenticateSSOTokenExchange(token, completionBlock: { (tokenExchangeError: Error?) in
                    if let error = tokenExchangeError {
                        completion(ServiceResult.Failure(ServiceError.Other(error: error)))
                    } else {
                        //TODO 3 - Get the user?
                        completion(ServiceResult.Success("Success"))
                    }
                })
            case .Failure:
                completion(result)
            }
        }
    }
    
    /// Fetch the authorization token for the given credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    ///   - completion: the completion block to execute.
    private func fetchAuthToken(username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void) {
        
        var urlComponents = URLComponents(string: Environment.sharedInstance.oAuthEndpoint)!
        
        urlComponents.queryItems = [
            URLQueryItem(name: OAuthQueryParams.Username.rawValue, value: Environment.sharedInstance.opco.uppercased() + "\\" + username),
            URLQueryItem(name: OAuthQueryParams.Password.rawValue, value: password),
            URLQueryItem(name: OAuthQueryParams.Encode.rawValue, value: "compress")
        ]
        
        let task = URLSession.shared.dataTask(with: urlComponents.url!) {(data, response, error) in
            let serviceResponse = AuthTokenParser.parseAuthTokenResponse(data: data, response: response, error: error)
            completion(serviceResponse)
        }
        
        task.resume()
    }
    
    // OMC Logout Implementation
    func logout(completion: @escaping (ServiceResult<Void>) -> Void) {
        
        let backend = OMCMobileBackendManager.shared().defaultMobileBackend
        let auth = backend?.authorization
        
        auth?.logoutClearCredentials(true, completionBlock: { (error: Error?) in
            if error != nil {
                completion(ServiceResult.Failure(ServiceError.Other(error: error!)))
            } else {
                completion(ServiceResult.Success())
            }
        })
    }
    
    // OMC Change Password Implementation
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
        let backend = OMCMobileBackendManager.shared().defaultMobileBackend
        let client = backend?.customCodeClient
        
        let params = [ChangePasswordParams.OldPassword.rawValue: currentPassword,
                      ChangePasswordParams.NewPassword.rawValue: newPassword]
        
        client?.invokeCustomRequest("auth/profile/password", method:HttpMethod.Put.rawValue, data: params, completion: { (error: Error?, response: HTTPURLResponse?, data: Any?) in
            
            let result = OMCResponseParser.parse(data: data, error: error, response: response)
            
            switch result {
            case .Success:
                completion(ServiceResult.Success())
                break
            case .Failure(let err):
                completion(ServiceResult.Failure(err))
                break
            }
        })
    }

}
