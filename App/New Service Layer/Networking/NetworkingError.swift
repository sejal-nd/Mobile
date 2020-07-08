//
//  NetworkingError.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public enum NetworkingError: Error, Equatable {
    case invalidToken
    case invalidURL
    case invalidResponse
    case invalidData
    case decoding
    case noNetwork
    case generic
    
    // FN Service Errors
    case invalidProfile
    case noPasswordMatch
    case invalidPassword
    case loginLocked // Login - attempted to login with password protected account. We throw this error, not from web services
    case accountNotActivated // Login - attempted to login before verifying email from registration. We throw this error, not from web services
    case unknown
    case incorrectSecurityQuestion // Forgot Username - security question answered incorrectly
    case profileNotFound // Forgot Username/Password - profile not found
    case accountNotFound // Forgot Username/Password - account not found
    case lockedForgotPassword // Forgot username - answered security question incorrectly too many times
    case accountLookupNotFound // Account lookup tool not found
    case passwordProtected // Login - Password protected accounts can't login to app
    case duplicatePaymentMethod // Wallet - user tries to add duplicate payment method
    case multipleAccountNumbers // Registration scenario for BGE with multiple account numbers
    case noProfileExists
    case finaled // Loading outage status for finaled account
    case noPay // Loading outage status for no-pay account
    case noService // Loading outage status for BGE non-service agreement account
    case inactive // Account is no lonnger active
    case notCustomer
    case invalidUser
    case userExists
    case maintenanceMode
    case multiAccount // Forgot Username scenario for BGE with multiple account numbers
    case expiredTempPassword // Temp password older than an hour
    case blockAccount // BGE only - blocks EDI and summary billing customers from the app
    case peakRewardsOverridesNotFound // BGE PeakRewards overrides not found
    case peakRewardsDuplicateOverrides // BGE PeakRewards overrides already exists
    case peakRewardsOverrides // BGE PeakRewards overrides
    case failed // ComEd/PECO /payments endpoint with no scheduled payments
    case noEventResults // BGE /programs endpoint with no eventResults
    
    init(errorCode: String) {
        switch errorCode {
        case "INVALID-PROFILE-TYPE":
            self = .invalidProfile
        case "FN-PWD-NOMATCH":
            self = .noPasswordMatch
        case "FN-PWD-INVALID":
            self = .invalidPassword
        case "FN-ACCT-LOCKED-LOGIN":
            self = .loginLocked
        case "FN-ACCT-NOT-ACTIVATED":
            self = .accountNotActivated
        case "TC-UNKNOWN":
            self = .unknown
        case "FN-PROF-BADSECURITY":
            self = .incorrectSecurityQuestion
        case "FN-PROF-NOTFOUND":
            self = .profileNotFound
        case "FN-ACCT-NOTFOUND":
            self = .accountNotFound
        case "FN-LOCKED-PWD":
            self = .lockedForgotPassword
        case "FN-NOT-FOUND":
            self = .accountLookupNotFound
        case "FN-ACCT-PROTECTED":
            self = .passwordProtected
        case "DUPLICATE_PAYMENT_ACCOUNT":
            self = .duplicatePaymentMethod
        case "FN-ACCT-MULTIPLE":
            self = .multipleAccountNumbers
        case "FN-PROF-EXISTS":
            self = .noProfileExists
        case "FN-ACCOUNT-FINALED":
            self = .finaled
        case "FN-ACCOUNT-NOPAY":
            self = .noPay
        case "FN-NON-SERVICE":
            self = .noService
        case "FN-ACCOUNT-INACTIVE":
            self = .inactive
        case "FN-CUST-NOTFOUND":
            self = .notCustomer
        case "FN-USER-INVALID":
            self = .invalidUser
        case "FN-USER-EXISTS":
            self = .userExists
        case "TC-SYS-MAINTENANCE":
            self = .maintenanceMode
        case "FN-MULTI-ACCT-FOUND":
            self = .multiAccount
        case "EXPIRED-TEMP-PASSWORD":
            self = .expiredTempPassword
        case "FN-ACCT-DISALLOW":
            self = .blockAccount
        case "FN-OVER-NOTFOUND":
            self = .peakRewardsOverridesNotFound
        case "FN-OVER-EXISTS":
            self = .peakRewardsDuplicateOverrides
        case "FN-OVER-OTHER":
            self = .peakRewardsOverrides
        case "FAILED":
            self = .failed
        case "FUNCTIONAL ERROR":
            self = .noEventResults
        default:
            self = .generic
        }
    }
}



// todo: below will be implemented for user facing messages.
extension NetworkingError: LocalizedError {
    public var title: String {
        return NSLocalizedString("Todo Title", comment: "Error title")
    }
    
    public var description: String {
        return NSLocalizedString("todo error dec", comment: "Error description")
        //        switch self {
        //        case .tooShort:
        //            return NSLocalizedString(
        //                "Your username needs to be at least 4 characters long",
        //                comment: ""
        //            )
        //        case .tooLong:
        //            return NSLocalizedString(
        //                "Your username can't be longer than 14 characters",
        //                comment: ""
        //            )
        //        case .invalidCharacterFound(let character):
        //            let format = NSLocalizedString(
        //                "Your username can't contain the character '%@'",
        //                comment: ""
        //            )
        //
        //            return String(format: format, String(character))
        //        }
    }
}
