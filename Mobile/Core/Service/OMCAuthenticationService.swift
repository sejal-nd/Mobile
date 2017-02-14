//
//  OMCAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

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
    func login(username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void) {
        
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
            let serviceResponse = self.parseAuthTokenResponse(data: data, response: response, error: error)
            completion(serviceResponse)
        }
        
        task.resume()
    }
    
    /// Parse the response received from an authorization token request.
    ///
    /// - Parameters:
    ///   - data: the raw response data.
    ///   - response: the url response.
    ///   - error: an error if once was received.
    /// - Returns: A ServiceResult with either the token on success, or a ServiceError for failure.
    private func parseAuthTokenResponse(data: Data?, response: URLResponse?, error: Error?) -> ServiceResult<String> {
        if let responseData = data {
            
            //TODO: Replace with DLog
            print(NSString(data: responseData, encoding: String.Encoding.utf8.rawValue) ?? "No Response Data")
            
            do {
                let parsedData = try JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
                let success = parsedData["success"] as! Bool
                
                if(success == false) {
                    return self.parseError(parsedData: parsedData)
                } else {
                    return self.parseSuccess(parsedData: parsedData)
                }
            } catch let err as NSError {
                return ServiceResult.Failure(ServiceError(errorCode: 0, errorMessage: "Unable to parse response. " + err.localizedDescription))
            }
            
        } else {
            if let message = error?.localizedDescription {
                return ServiceResult.Failure(ServiceError(errorCode: 0, errorMessage: message))
            } else {
                return ServiceResult.Failure(ServiceError(errorCode: 0, errorMessage: "An Unknown Error Occurred"))
            }
        }
    }
    
    
    /// Retrieves the assertion/token and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A successful ServiceResult containing the assertion/token
    private func parseSuccess(parsedData: [String:Any]) -> ServiceResult<String> {
        let data: NSDictionary = parsedData["data"] as! NSDictionary
        let assertion: String = data["assertion"] as! String
        
        return ServiceResult.Success(assertion)
    }
    
    
    /// Retreives the error and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A failure ServiceResult containing the error information.
    private func parseError(parsedData: [String:Any]) -> ServiceResult<String> {
        let meta: NSDictionary = parsedData["meta"] as! NSDictionary
        let code = meta["code"] as! String
        let description = meta["description"] as! String
        let serviceError = ServiceError(errorCode: code.hash, errorMessage: description)
        
        return ServiceResult.Failure(serviceError)
    }
    
    // OMC Logout Implementation
    func logout(completion: @escaping (ServiceResult<String>) -> Void) {
        //TODO: when the oracle sdk is available
        completion(ServiceResult.Success("loggedout@mail.com"))
    }
    
    // OMC Change Password Implementation
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (ServiceResult<String>) -> Void) {
        //TODO: when the oracle sdk is available
        completion(ServiceResult.Success("success"))
    }

}
