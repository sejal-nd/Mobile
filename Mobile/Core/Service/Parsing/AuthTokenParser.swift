//
//  AuthTokenParser.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class AuthTokenParser : NSObject {
    
    /// Parse the response received from an authorization token request.
    ///
    /// - Parameters:
    ///   - data: the raw response data.
    ///   - response: the url response.
    ///   - error: an error if once was received.
    /// - Returns: A ServiceResult with either the token on success, or a ServiceError for failure.
    class func parseAuthTokenResponse(data: Data?, response: URLResponse?, error: Error?) -> ServiceResult<String> {
        if let responseData = data {
            
            //TODO: Replace with DLog
            print(NSString(data: responseData, encoding: String.Encoding.utf8.rawValue) ?? "No Response Data")
            let vl = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue)
            
            do {
                
                let parsedData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
               
                
                if let success = parsedData["success"] as? Bool {
                    if(success == false) {
                        return self.parseError(parsedData: parsedData)
                    } else {
                        return self.parseSuccess(parsedData: parsedData)
                    }
                } else {
                    return ServiceResult.Failure(ServiceError.JSONParsing)
                }
                
                
            } catch let err as NSError {
                return ServiceResult.Failure(ServiceError.Other(error: err))
            }
            
        } else {
            return ServiceResult.Failure(ServiceError.Other(error: error!))
        }
    }
    
    
    /// Retrieves the assertion/token and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A successful ServiceResult containing the assertion/token
    class private func parseSuccess(parsedData: [String:Any]) -> ServiceResult<String> {
        let data: NSDictionary = parsedData["data"] as! NSDictionary
        let assertion: String = data["assertion"] as! String
        
        return ServiceResult.Success(assertion)
    }
    
    
    /// Retreives the error and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A failure ServiceResult containing the error information.
    class private func parseError(parsedData: [String:Any]) -> ServiceResult<String> {
        let meta: NSDictionary = parsedData["meta"] as! NSDictionary
        let code = meta["code"] as! String
        let description = meta["description"] as! String
        let serviceError = ServiceError.Custom(code: code, description: description)
        
        return ServiceResult.Failure(serviceError)
    }
}
