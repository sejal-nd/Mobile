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
    case TempPasswordFailReason = "reason"
}

private enum ProfileStatusNameValue : String {
    case LockedPassword = "isLockedPassword"
    case Inactive = "inactive"
    case Primary = "primary"
    case TempPassword = "tempPassword"
}

class AuthTokenParser : NSObject {
    
    /// Parse the response received from an authorization token request.
    ///
    /// - Parameters:
    ///   - data: the raw response data.
    ///   - response: the url response.
    ///   - error: an error if once was received.
    /// - Returns: A ServiceResult with either the token on success, or a ServiceError for failure.
    class func parseAuthTokenResponse(data: Data?, response: URLResponse?, error: Error?) -> ServiceResult<AuthTokenResponse> {
        if let responseData = data {
            
            dLog(message: String(data: responseData, encoding: String.Encoding.utf8) ?? "No Response Data")
            
            do {
                let parsedData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
                
                if let success = parsedData["success"] as? Bool {
                    if success == false {
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
    class private func parseSuccess(parsedData: [String:Any]) -> ServiceResult<AuthTokenResponse> {
        let data: NSDictionary = parsedData["data"] as! NSDictionary
        var profileStatus: ProfileStatus = ProfileStatus()
        
        if let statusData = data["profileStatus"] as? [String:Any] {
            profileStatus = parseProfileStatus(profileStatus: statusData)
            
            if profileStatus.passwordLocked {
                return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctLockedLogin.rawValue))
            } else if profileStatus.inactive {
                return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctNotActivated.rawValue))
            } else if profileStatus.expiredTempPassword {
                return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.ExpiredTempPassword.rawValue))
            }
        }
        
        guard let profileType = data["profileType"] as? String else {
           return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.InvalidProfileType.rawValue))
        }
        
        guard let customerIdentifier = data["customerIdentifier"] as? String else {
            return ServiceResult.Failure(ServiceError(serviceMessage: NSLocalizedString("Customer Identifier not found", comment: "")))
        }
        UserDefaults.standard.set(customerIdentifier, forKey: UserDefaultKeys.CustomerIdentifier)
        AccountsStore.sharedInstance.customerIdentifier = customerIdentifier
        
        UserDefaults.standard.set(profileType == "commercial", forKey: UserDefaultKeys.IsCommercialUser)
        if profileType != "commercial" && profileType != "residential" {
            return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.InvalidProfileType.rawValue))
        }
        
        if let assertion = data["assertion"] as? String {
            return ServiceResult.Success(AuthTokenResponse(token: assertion, profileStatus: profileStatus))
        } else {
            return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.TcUnknown.rawValue))
        }
        
    }
    
    
    /// Parse a ProfileStatus instance from json.
    ///
    /// - Parameter profileStatus: the json value to parse
    /// - Returns: a ProfileStatus
    class private func parseProfileStatus(profileStatus: [String:Any]) -> ProfileStatus {
        
        var lockedPassword = false;
        var inactive = false;
        var primary = false;
        var tempPassword = false;
        var expiredTempPassword = false;
        
        if let status = profileStatus[ProfileStatusKey.Status.rawValue] as? Array<NSDictionary> {
            for item in status {
                if let name = item[ProfileStatusKey.Name.rawValue] as? String {
                    switch name {
                    case ProfileStatusNameValue.LockedPassword.rawValue:
                        lockedPassword = item[ProfileStatusKey.Value.rawValue] as! Bool
                    case ProfileStatusNameValue.Inactive.rawValue:
                        inactive = item[ProfileStatusKey.Value.rawValue] as! Bool
                    case ProfileStatusNameValue.Primary.rawValue:
                        primary = item[ProfileStatusKey.Value.rawValue] as! Bool
                    case ProfileStatusNameValue.TempPassword.rawValue:
                        tempPassword = item[ProfileStatusKey.Value.rawValue] as! Bool
                        expiredTempPassword = item[ProfileStatusKey.TempPasswordFailReason.rawValue] as? String == "expired"
                    default:
                        break
                    }
                }
            }
        }
        
        return ProfileStatus(inactive:inactive, primary:primary, passwordLocked:lockedPassword, tempPassword: tempPassword,expiredTempPassword: expiredTempPassword)
    }
    
    /// Retreives the error and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A failure ServiceResult containing the error information.
    class private func parseError(parsedData: [String:Any]) -> ServiceResult<AuthTokenResponse> {
        let meta: NSDictionary = parsedData["meta"] as! NSDictionary
        let code = meta[OMCResponseKey.Code.rawValue] as! String
        let description = meta[OMCResponseKey.Description.rawValue] as! String
        
        if let data = parsedData[OMCResponseKey.Data.rawValue] as? [String:Any] {
            if let statusData = data[ProfileStatusKey.ProfileStatus.rawValue] as? [String:Any] {
                let profileStatus = parseProfileStatus(profileStatus: statusData)
            
                if profileStatus.passwordLocked {
                    return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctLockedLogin.rawValue))
                } else if profileStatus.inactive {
                    return ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAcctNotActivated.rawValue))
                }
            }
        }
        let serviceError = ServiceError(serviceCode: code, serviceMessage: description)
        return ServiceResult.Failure(serviceError)
    }
}
