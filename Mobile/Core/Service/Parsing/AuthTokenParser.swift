//
//  AuthTokenParser.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

private enum ProfileStatusKey : String {
    case ProfileStatus = "profileStatus"
    case Status = "status"
    case Name = "name"
    case Value = "value"
    case Offset = "offset"
}

private enum ProfileStatusNameValue : String {
    case LockedPassword = "isLockedPassword"
    case Active = "active"
    case Primary = "primary"
}

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
            
            dLog(message: String(data: responseData, encoding: String.Encoding.utf8) ?? "No Response Data")
            
            do {
                let parsedData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
                
                if let success = parsedData["success"] as? Bool {
                    if(success == false) {
                        return self.parseError(parsedData: parsedData)
                    } else {
                        return self.parseSuccess(parsedData: parsedData)
                    }
                } else {
                    return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue))
                }
                
            } catch let err as NSError {
                return ServiceResult.Failure(ServiceError(cause: err))
            }
            
        } else {
            return ServiceResult.Failure(ServiceError(cause: error!))
        }
    }
    
    
    /// Retrieves the assertion/token and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A successful ServiceResult containing the assertion/token
    class private func parseSuccess(parsedData: [String:Any]) -> ServiceResult<String> {
        let data: NSDictionary = parsedData["data"] as! NSDictionary
        let assertion: String = data["assertion"] as! String
    
        if let statusData = data["profileStatus"] as? [String:Any] {
            let profileStatus = parseProfileStatus(profileStatus: statusData)
            
            if(profileStatus.passwordLocked) {
                return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctLockedLogin.rawValue))
            }
        }
        
        return ServiceResult.Success(assertion)
    }
    
    
    /// Parse a ProfileStatus instance from json.
    ///
    /// - Parameter profileStatus: the json value to parse
    /// - Returns: a ProfileStatus
    class private func parseProfileStatus(profileStatus: [String:Any]) -> ProfileStatus {
        
        var lockedPassword = false;
        var active  = false;
        var primary  = false;
        
        if let status = profileStatus[ProfileStatusKey.Status.rawValue] as? Array<NSDictionary> {
            for item in status {
                if let name = item[ProfileStatusKey.Name.rawValue] as? String {
                    switch name {
                    case ProfileStatusNameValue.LockedPassword.rawValue:
                        lockedPassword = item[ProfileStatusKey.Value.rawValue] as! Bool
                        break
                    case ProfileStatusNameValue.Active.rawValue:
                        active = item[ProfileStatusKey.Value.rawValue] as! Bool
                        break
                    case ProfileStatusNameValue.Primary.rawValue:
                        primary = item[ProfileStatusKey.Value.rawValue] as! Bool
                    default:
                        break
                    }
                }
            }
        }
        
        return ProfileStatus(active:active, primary:primary, passwordLocked:lockedPassword)
    }
    
    /// Retreives the error and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A failure ServiceResult containing the error information.
    class private func parseError(parsedData: [String:Any]) -> ServiceResult<String> {
        let meta: NSDictionary = parsedData["meta"] as! NSDictionary
        let code = meta[OMCResponseKey.Code.rawValue] as! String
        let description = meta[OMCResponseKey.Description.rawValue] as! String
        
        if let data = parsedData[OMCResponseKey.Data.rawValue] as? [String:Any] {
            if let statusData = data[ProfileStatusKey.ProfileStatus.rawValue] as? [String:Any] {
                let profileStatus = parseProfileStatus(profileStatus: statusData)
            
                if(profileStatus.passwordLocked) {
                    return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctLockedLogin.rawValue))
                }
            }
        }
        let serviceError = ServiceError(serviceCode: code, serviceMessage: description)
        return ServiceResult.Failure(serviceError)
    }
}
