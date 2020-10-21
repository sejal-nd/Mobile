//
//  NetworkingError.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public enum NetworkingError: Error, Equatable {
    // Network Layer Errors
    case invalidToken // Login - tokens out of sync with server or expired
    case invalidURL
    case invalidResponse
    case invalidData
    case decoding
    case noNetwork
    case generic
    case reverseGeocodeFailure
    
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
    case failedLogin //
    
    // Paymentus Errors
    case blockedPaymentMethod
    case blockedUtilityAccount
    case blockedPaymentType
    case duplicatePayment
    case paymentAccountVelocityBank
    case paymentAccountVelocityCard
    case utilityAccountVelocity
    case walletItemIdTimeout
    
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
        case "FN-FAIL-LOGIN", "FN_ACCT_INVALID":
            self = .failedLogin
        case "FAILED":
            self = .failed
        case "FUNCTIONAL ERROR":
            self = .noEventResults
        case "xmlPayment.declined":
            self = .blockedPaymentMethod
        case "accountNumber.suspended":
            self = .blockedUtilityAccount
        case "paymentMethodType.blocked":
            self = .blockedPaymentType
        case "xmlPayment.duplicate":
            self = .duplicatePayment
        case "pmBankAccount.tooManyPerPaymentMethodType":
            self = .paymentAccountVelocityBank
        case "pmCreditCardNumber.tooManyPerPaymentMethodType":
            self = .paymentAccountVelocityCard
        case "accountNumber.tooManyPerPaymentType":
            self = .utilityAccountVelocity
        case "tokenizedProfile.notProcessed":
            self = .walletItemIdTimeout
        default:
            self = .generic
        }
    }
}

// MARK: User Facing Error Messaging

extension NetworkingError: LocalizedError {
    public var title: String {
        switch self {
        case .inactive:
            return NSLocalizedString("Inactive Account", comment: "Error title")
        case .notCustomer, .invalidUser:
            return NSLocalizedString("No Data Found", comment: "Error title")
        case .userExists:
            return NSLocalizedString("Email Already Registered", comment: "Error title")
        case .maintenanceMode:
            return NSLocalizedString("Service Unavailable", comment: "Error title")
        case .expiredTempPassword:
            return NSLocalizedString("Expired Temporary Password", comment: "Error title")
        case .blockAccount:
            return NSLocalizedString("Data Unavailable", comment: "Error title")
        case .peakRewardsOverridesNotFound:
            return NSLocalizedString("Overrides Not Found", comment: "Error title")
        case .peakRewardsDuplicateOverrides:
            return NSLocalizedString("Duplicate Override", comment: "Error title")
        case .failedLogin:
            return ""
        case .failed:
            return NSLocalizedString("Scheduled Payments Not Found", comment: "Error title")
        case .noEventResults:
            return NSLocalizedString("No Results Found", comment: "Error title")
        case .accountNotActivated:
            return NSLocalizedString("Your Account Needs to be Activated", comment: "Error title")
        case .incorrectSecurityQuestion:
            return NSLocalizedString("Answer Doesn't Match", comment: "Error title")
        case .profileNotFound:
            return NSLocalizedString("Your verification link is no longer valid", comment: "")
        case .accountNotFound:
            return NSLocalizedString("No Account Found", comment: "Error title")
        case .lockedForgotPassword:
            return NSLocalizedString("Account Locked", comment: "Error title")
        case .passwordProtected:
            return NSLocalizedString("Password Protected", comment: "Error title")
        case .duplicatePaymentMethod:
            return NSLocalizedString("Duplicate Payment Method", comment: "Error title")
        case .finaled:
            return NSLocalizedString("Finaled Account", comment: "Error title")
        case .noPay:
            return NSLocalizedString("Finaled for Non-Pay", comment: "Error title")
        case .noService:
            return NSLocalizedString("Non-Service Agreement", comment: "Error title")
        case .invalidToken:
            return NSLocalizedString("Expired Session", comment: "Error title")
        case .noNetwork:
            return NSLocalizedString("No Network Connection", comment: "Error title")
        case .noPasswordMatch, .invalidPassword:
            return NSLocalizedString("Wrong Password", comment: "Error title")
        case .loginLocked:
            return NSLocalizedString("Password Protected Account", comment: "Error title")
        case .reverseGeocodeFailure:
            return NSLocalizedString("Address Not Found", comment: "Error title")
        case .multipleAccountNumbers, .multiAccount:
            return NSLocalizedString("Multiple Accounts Found", comment: "Error title")
        case .blockedPaymentMethod:
            return NSLocalizedString("Payment Method Blocked", comment: "Error title")
        case .blockedUtilityAccount:
            return NSLocalizedString("Locked Account", comment: "Error title")
        case .blockedPaymentType:
            return NSLocalizedString("Payment Type Blocked", comment: "Error title")
        case .duplicatePayment:
            return NSLocalizedString("Duplicate Payment", comment: "Error title")
        case .paymentAccountVelocityBank, .paymentAccountVelocityCard:
            return NSLocalizedString("Payment Issue", comment: "Error title")
        case .walletItemIdTimeout:
            return NSLocalizedString("Password Protected Account", comment: "Error title")
        case .peakRewardsOverrides, .unknown, .accountLookupNotFound, .noProfileExists, .invalidURL, .invalidResponse, .invalidData, .decoding, .generic, .invalidProfile, .utilityAccountVelocity:
            return NSLocalizedString("Sorry, That Didn't Quite Work.", comment: "Error title")
        }
    }
    
    public var description: String {
        switch self {
        case .inactive:
            return NSLocalizedString("We can’t load data for this account because it is no longer active.", comment: "Error description")
        case .notCustomer, .invalidUser:
            return NSLocalizedString("There was no data associated with this account.", comment: "Error description")
        case .userExists:
            return NSLocalizedString("This email is already associated with another account. Please use a different email.", comment: "Error description")
        case .maintenanceMode:
            return NSLocalizedString("Our backend systems are currently being updated and can’t provide data at this time. Please try again later.", comment: "Error description")
        case .expiredTempPassword:
            return NSLocalizedString("Your temporary password has expired.", comment: "Error description")
        case .blockAccount:
            return NSLocalizedString("This data is unavailable for this account.", comment: "Error description")
        case .peakRewardsOverridesNotFound:
            return NSLocalizedString("No overrides were found. Please try again later.", comment: "Error description")
        case .peakRewardsDuplicateOverrides:
            return NSLocalizedString("This override is already scheduled.", comment: "Error description")
        case .failedLogin:
            return NSLocalizedString("We're sorry, this combination of email and password is invalid. Please try again. Too many consecutive attempts may result in your account being temporarily locked.", tableName: "ErrorMessages", comment: "")
            
        case .failed:
            return NSLocalizedString("No scheduled payments were found for this account.", comment: "Error description")
        case .noEventResults:
            return NSLocalizedString("No events were found for this account.", comment: "Error description")
        case .accountNotActivated:
            return NSLocalizedString("Find and click on the link in the email from \(Environment.shared.opco.displayString) within 48 hours from the time you registered. Once the link expires, you’ll need to re-register your account.", comment: "Error description")
        case .incorrectSecurityQuestion:
            return NSLocalizedString("Sorry, the answer to the security question isn’t right. Too many tries may result in your account becoming locked for 15 minutes.", comment: "Error description")
        case .profileNotFound:
            return NSLocalizedString("If you have already verified your account, please sign in to access your account. If your link has expired, please re-register.", comment: "")
        case .accountNotFound:
            return NSLocalizedString("Sorry, we couldn’t find an account with that email address.", comment: "Error description")
        case .lockedForgotPassword:
            return NSLocalizedString("Access to this account is locked because of too many incorrect security question attempts. It may be locked out for the next 15 minutes. Please try again later.", comment: "Error description")
        case .passwordProtected:
            return NSLocalizedString("Your account is password protected and can’t be accessed through this app.", comment: "Error description")
        case .duplicatePaymentMethod:
            return NSLocalizedString("This payment method is already saved to your wallet.", comment: "Error description")
        case .finaled:
            return NSLocalizedString("We can’t load the outage status for this account because it’s been closed.", comment: "Error description")
        case .noPay:
            return NSLocalizedString("We can’t load the outage status for this account because it’s been closed for non-payment and is no longer connected to your premise address.", comment: "Error description")
        case .noService:
            return NSLocalizedString("We can’t load the outage status for this account due to a non-service agreement.", comment: "Error description")
        case .invalidToken:
            return NSLocalizedString("You’ve been signed out. To start a new session, please sign in.", comment: "Error description")
        case .noNetwork:
            return NSLocalizedString("Please make sure you’re connected to the internet and refresh to try again.", comment: "Error description")
        case .noPasswordMatch, .invalidPassword:
            return NSLocalizedString("Sorry, that password isn’t right.", comment: "Error description")
        case .loginLocked:
            return NSLocalizedString("Your account is password protected and can’t be accessed through this app.", comment: "Error description")
        case .reverseGeocodeFailure:
            return NSLocalizedString("Please try again later.", comment: "Error description")
        case .multipleAccountNumbers, .multiAccount:
            return NSLocalizedString("Multiple Accounts Found", comment: "Error description")
        case .blockedPaymentMethod:
            return NSLocalizedString("Please try a different payment method.", comment: "Error description")
        case .blockedUtilityAccount:
            return NSLocalizedString("Your account is locked from making payments. Please call customer service.", comment: "Error description")
        case .blockedPaymentType:
            return NSLocalizedString("Please try a different payment type.", comment: "Error description")
        case .duplicatePayment:
            return NSLocalizedString("We found a duplicate payment.", comment: "Error description")
        case .paymentAccountVelocityBank, .paymentAccountVelocityCard:
            return NSLocalizedString("Please try again later.", comment: "Error description")
        case .walletItemIdTimeout:
            return NSLocalizedString("Your account is password protected and can’t be accessed through this app.", comment: "Error description")
        case .peakRewardsOverrides, .unknown, .accountLookupNotFound, .noProfileExists, .invalidURL, .invalidResponse, .invalidData, .decoding, .generic, .invalidProfile, .utilityAccountVelocity:
            return NSLocalizedString("Please try again later.", comment: "Error description")
        }
    }
}
