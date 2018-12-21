//
//  AuthTokenParser.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

private enum ProfileStatusKey : String {
    case profileStatus = "profileStatus"
    case status = "status"
    case name = "name"
    case value = "value"
    case offset = "offset"
    case tempPasswordFailReason = "reason"
}

private enum ProfileStatusNameValue : String {
    case lockedPassword = "isLockedPassword"
    case inactive = "inactive"
    case primary = "primary"
    case tempPassword = "tempPassword"
}

class AuthTokenParser : NSObject {
    
    /// Parse the response received from an authorization token request.
    ///
    /// - Parameters:
    ///   - data: the raw response data.
    ///   - response: the url response.
    ///   - error: an error if once was received.
    /// - Returns: A ServiceResult with either the token on success, or a ServiceError for failure.
    class func parseAuthTokenResponse(data: Data) -> ServiceResult<AuthTokenResponse> {
        do {
            let parsedData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
            
            if let success = parsedData["success"] as? Bool {
                if success == false {
                    return self.parseError(parsedData: parsedData)
                } else {
                    return self.parseSuccess(parsedData: parsedData)
                }
            } else {
                return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue))
            }
        } catch let err as NSError {
            return ServiceResult.failure(ServiceError(cause: err))
        }
    }
    
    
    /// Retrieves the assertion/token and wrap it in a ServiceResult
    ///
    /// - Parameter parsedData: The dictionary that was parsed from the response.
    /// - Returns: A successful ServiceResult containing the assertion/token
    class private func parseSuccess(parsedData: [String:Any]) -> ServiceResult<AuthTokenResponse> {
        let data: NSDictionary = parsedData["data"] as! NSDictionary
        var profileStatus: ProfileStatus = ProfileStatus()
        
        guard let profileType = data["profileType"] as? String,
            (profileType == "commercial" || profileType == "residential") else {
                return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.invalidProfileType.rawValue))
        }
        
        guard let statusData = data["profileStatus"] as? [String:Any] else {
            return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue))
        }
        
        profileStatus = parseProfileStatus(profileStatus: statusData)
        
        guard !profileStatus.inactive else {
            return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.fnAcctNotActivated.rawValue))
        }
        
        guard let customerIdentifier = data["customerIdentifier"] as? String else {
            return ServiceResult.failure(ServiceError(serviceMessage: NSLocalizedString("Customer Identifier not found", comment: "")))
        }
        
        UserDefaults.standard.set(customerIdentifier, forKey: UserDefaultKeys.customerIdentifier)
        AccountsStore.shared.customerIdentifier = customerIdentifier
        
        if let assertion = data["assertion"] as? String {
            // SUCCESS
            return ServiceResult.success(AuthTokenResponse(token: assertion, profileStatus: profileStatus))
        }
        
        guard !profileStatus.passwordLocked else {
            return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.fnAcctLockedLogin.rawValue))
        }
        
        guard !profileStatus.expiredTempPassword else {
            return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.expiredTempPassword.rawValue))
        }
        
        
        return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue))
    }
    
    
    /// Parse a ProfileStatus instance from json.
    ///
    /// - Parameter profileStatus: the json value to parse
    /// - Returns: a ProfileStatus
    class private func parseProfileStatus(profileStatus: [String:Any]) -> ProfileStatus {
        
        var lockedPassword = false
        var inactive = false
        var primary = false
        var tempPassword = false
        var expiredTempPassword = false
        
        if let status = profileStatus[ProfileStatusKey.status.rawValue] as? Array<NSDictionary> {
            for item in status {
                if let name = item[ProfileStatusKey.name.rawValue] as? String {
                    switch name {
                    case ProfileStatusNameValue.lockedPassword.rawValue:
                        lockedPassword = item[ProfileStatusKey.value.rawValue] as! Bool
                    case ProfileStatusNameValue.inactive.rawValue:
                        inactive = item[ProfileStatusKey.value.rawValue] as! Bool
                    case ProfileStatusNameValue.primary.rawValue:
                        primary = item[ProfileStatusKey.value.rawValue] as! Bool
                    case ProfileStatusNameValue.tempPassword.rawValue:
                        tempPassword = item[ProfileStatusKey.value.rawValue] as! Bool
                        expiredTempPassword = item[ProfileStatusKey.tempPasswordFailReason.rawValue] as? String == "expired"
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
        let code = meta[MCSResponseKey.Code.rawValue] as! String
        let description = meta[MCSResponseKey.Description.rawValue] as! String
        
        if let data = parsedData[MCSResponseKey.Data.rawValue] as? [String:Any] {
            if let statusData = data[ProfileStatusKey.profileStatus.rawValue] as? [String:Any] {
                let profileStatus = parseProfileStatus(profileStatus: statusData)
            
                if profileStatus.passwordLocked {
                    return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.fnAcctLockedLogin.rawValue))
                } else if profileStatus.inactive {
                    return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.fnAcctNotActivated.rawValue))
                }
            }
        }
        let serviceError = ServiceError(serviceCode: code, serviceMessage: description)
        return ServiceResult.failure(serviceError)
    }
}
