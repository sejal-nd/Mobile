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
    case localError = "LocalError"
    case noNetworkConnection = "ERR-NO-NETWORK-CONNECTION"
    case invalidProfileType = "INVALID-PROFILE-TYPE"
    case parsing = "Parsing"
    case fNPwdNoMatch = "FN-PWD-NOMATCH"
    case fnPwdInvalid = "FN-PWD-INVALID"
    case fnAcctLockedLogin = "FN-ACCT-LOCKED-LOGIN" // Login - attempted to login with password protected account. We throw this error, not from web services
    case fnAcctNotActivated = "FN-ACCT-NOT-ACTIVATED" // Login - attempted to login before verifying email from registration. We throw this error, not from web services
    case tcUnknown = "TC-UNKNOWN"
    case fnProfBadSecurity = "FN-PROF-BADSECURITY" // Forgot Username - security question answered incorrectly
    case fnProfNotFound = "FN-PROF-NOTFOUND" // Forgot Username/Password - profile not found
    case fnAccountNotFound = "FN-ACCT-NOTFOUND" // Forgot Username/Password - account not found
    case fnLockedPwd = "FN-LOCKED-PWD" // Forgot username - answered security question incorrectly too many times
    case fnNotFound = "FN-NOT-FOUND" // Account lookup tool not found
    case fnAccountProtected = "FN-ACCT-PROTECTED" // Login - Password protected accounts can't login to app
    case dupPaymentAccount = "DUPLICATE_PAYMENT_ACCOUNT" // Wallet - user tries to add duplicate payment method
    case fnAccountMultiple = "FN-ACCT-MULTIPLE" // Registration scenario for BGE with multiple account numbers
    case fnProfileExists = "FN-PROF-EXISTS"
    case fnAccountFinaled = "FN-ACCOUNT-FINALED" // Loading outage status for finaled account
    case fnAccountNoPay = "FN-ACCOUNT-NOPAY" // Loading outage status for no-pay account
    case fnNonService = "FN-NON-SERVICE" // Loading outage status for BGE non-service agreement account
    case fnCustomerNotFound = "FN-CUST-NOTFOUND"
    case fnUserInvalid = "FN-USER-INVALID"
    case fnUserExists = "FN-USER-EXISTS"
    case maintenanceMode = "TC-SYS-MAINTENANCE"
    case fnMultiAccountFound = "FN-MULTI-ACCT-FOUND" // Forgot Username scenario for BGE with multiple account numbers
    case expiredTempPassword = "EXPIRED-TEMP-PASSWORD" // Temp password older than an hour
    case fnAccountDisallow = "FN-ACCT-DISALLOW" // BGE only account blocking mechanism
    case fnOverNotFound = "FN-OVER-NOTFOUND" // BGE PeakRewards overrides not found
    case fnOverExists = "FN-OVER-EXISTS" // BGE PeakRewards overrides already exists
    case fnOverOther = "FN-OVER-OTHER" // BGE PeakRewards overrides
    case failed = "FAILED" // ComEd/PECO /payments endpoint with no scheduled payments
    case functionalError = "FUNCTIONAL ERROR" // BGE /programs endpoint with no eventResults
    
    // Paymentus Errors
    case blockedPaymentMethod = "xmlPayment.declined"
    case blockedUtilityAccount = "accountNumber.suspended"
    case blockedPaymentType = "paymentMethodType.blocked"
    case duplicatePayment = "xmlPayment.duplicate"
    case paymentAccountVelocityBank = "pmBankAccount.tooManyPerPaymentMethodType"
    case paymentAccountVelocityCard = "pmCreditCardNumber.tooManyPerPaymentMethodType"
    case utilityAccountVelocity = "accountNumber.tooManyPerPaymentType"
    case walletItemIdTimeout = "tokenizedProfile.notProcessed"
}

// MARK: - ServiceError

/// A representation of an error case at the service level.
struct ServiceError : Error {
    let serviceCode: String
    var serviceMessage: String?
    var cause: Error?
    
    init(serviceCode: String = ServiceErrorCode.localError.rawValue, serviceMessage: String? = nil, cause: Error? = nil) {
        self.serviceCode = serviceCode
        self.serviceMessage = serviceMessage
        self.cause = cause
    }
}


// MARK: - ServiceError -> LocalizedError

/// Adds LocalizedDescription to ServiceError
extension ServiceError : LocalizedError {
    public var errorDescription: String? {
        
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
    case success(T)
    case failure(ServiceError)
}
