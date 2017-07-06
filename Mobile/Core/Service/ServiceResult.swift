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
    case NoNetworkConnection = "ERR-NO-NETWORK-CONNECTION"
    case InvalidProfileType = "INVALID-PROFILE-TYPE"
    case Parsing = "Parsing"
    case FNPwdNoMatch = "FN-PWD-NOMATCH"
    case FnPwdInvalid = "FN-PWD-INVALID"
    case FnAcctLockedLogin = "FN-ACCT-LOCKED-LOGIN" // Login - attempted to login with password protected account. We throw this error, not from web services
    case FnAcctNotActivated = "FN-ACCT-NOT-ACTIVATED" // Login - attempted to login before verifying email from registration. We throw this error, not from web services
    case TcUnknown = "TC-UNKNOWN"
    case FnProfBadSecurity = "FN-PROF-BADSECURITY" // Forgot Username - security question answered incorrectly
    case FnProfNotFound = "FN-PROF-NOTFOUND" // Forgot Username/Password - profile not found
    case FnAccountNotFound = "FN-ACCT-NOTFOUND" // Forgot Username/Password - account not found
    case FnNotFound = "FN-NOT-FOUND" // Account lookup tool not found
    case FnAccountProtected = "FN-ACCT-PROTECTED" // Login - Password protected accounts can't login to app
    case DupPaymentAccount = "DUPLICATE_PAYMENT_ACCOUNT" // Wallet - user tries to add duplicate payment method
    case FnAccountMultiple = "FN-ACCT-MULTIPLE" // Registration scenario for BGE with multiple account numbers
    case FnProfileExists = "FN-PROF-EXISTS"
    case FnAccountFinaled = "FN-ACCOUNT-FINALED" // Loading outage status for finaled account
    case FnAccountNoPay = "FN-ACCOUNT-NOPAY" // Loading outage status for no-pay account
    case FnCustomerNotFound = "FN-CUST-NOTFOUND"
    case FnUserInvalid = "FN-USER-INVALID"
    case FnUserExists = "FN-USER-EXISTS"
    case FnMultiAccountFound = "FN-MULTI-ACCT-FOUND" // Forgot Username scenario for BGE with multiple account numbers
    case ExpiredTempPassword = "EXPIRED-TEMP-PASSWORD" // Temp password older than an hour
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
    public var errorDescription: String {
        
        if let cause = cause {
            return cause.localizedDescription
        } else {
            let description = NSLocalizedString(serviceCode, tableName: "ErrorMessages", comment: "")
            if(description != serviceCode) {
                return description
            } else if let serviceMessage = serviceMessage {
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
