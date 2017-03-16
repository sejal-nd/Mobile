//
//  ServiceResult.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

// MARK: - ServiceErrorCode

enum ServiceErrorCode : String {
    case LocalError = "LocalError"
    case InvalidProfileType = "INVALID-PROFILE-TYPE"
    case Parsing = "Parsing"
    case TCNotImplemented = "TC-NOTIMPL"
    case FNFailLogin = "FN-FAIL-LOGIN"
    case TCFailLogin = "TC_FAIL-LOGIN"
    case TCGrantInvalid = "TC-GRANT-INVALID"
    case FNPwdNoMatch = "FN-PWD-NOMATCH"
    case FnPwdStrength = "FN-PWD-STRENGTH"
    case FnPwdInvalid = "FN-PWD-INVALID"
    case FnAcctLocked = "FN-ACCT-LOCKED"
    case FnAcctLockedLogin = "FN-ACCT-LOCKED-LOGIN"
    case FnUnknown = "FN-UNKNOWN"
    case TcAcctInvalid = "TC-ACCT-INVALID"
    case TcUserInvalid = "TC-USER-INVALID"
}

// MARK: - ServiceError

/// A representation of an error case at the service level.
struct ServiceError : Error {
    let serviceCode: String
    var serviceMessage: String?
    var cause: Error?
    
    init(serviceCode: String = ServiceErrorCode.LocalError.rawValue, serviceMessage: String? = nil, cause: Error? = nil) {
        self.serviceCode = serviceCode
        self.serviceMessage = serviceMessage != nil ? serviceMessage! : nil
        self.cause = cause != nil ? cause! : nil
    }
}


// MARK: - ServiceError -> LocalizedError

/// Adds LocalizedDescription to ServiceError
extension ServiceError : LocalizedError {
    public var errorDescription: String? {
        
        if(cause != nil) {
            return cause?.localizedDescription
        } else {
            let description = NSLocalizedString(serviceCode, tableName: "ErrorMessages", comment: "")
            if(description != serviceCode) {
                return description
            } else if serviceMessage != nil {
                return serviceMessage
            } else {
                return "An unknown error occurred (" + serviceCode + ")"
            }
        }
    }
}

// MARK: - ServiceResult

/// A representation of the result of a service request.
///
/// - Success: Indicates that the request successfully completed. The
///             resulting data is supplied.
/// - Failure: Indicates that the request failed. The underlying cause
///             of the failure is supplied with a ServiceError.
enum ServiceResult<T> {
    case Success(T)
    case Failure(ServiceError)
}
