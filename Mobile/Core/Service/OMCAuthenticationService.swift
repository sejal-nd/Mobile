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

class OMCAuthenticationService : AuthenticationService {
    
    // OMC Login Implementation
    // Steps:
    //  1. Retreive token from api gateway
    //  2. Exchange the token with the Oracle SDK
    //  3. Fetch the user through the Oracle SDK
    func login(_ username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void) {
        
        //1
        fetchAuthToken(username: username, password: password) { (result: ServiceResult<String>) in
            //2 - TODO: when the oracle SDK is available
            //3 - TODO: when the oracle SDK is available
            completion(result)
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
            URLQueryItem(name: OAuthQueryParams.Username.rawValue, value: Environment.sharedInstance.opco + "\\" + username),
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
    func logout(completion: @escaping (ServiceResult<String>) -> Void) {
        //TODO: when the oracle sdk is available
        completion(ServiceResult.Success("loggedout@mail.com"))
    }
    
    // OMC Change Password Implementation
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (ServiceResult<String>) -> Void) {
        //TODO: when the oracle sdk is available
        completion(ServiceResult.Success("success"))
    }

}
