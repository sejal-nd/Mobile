//
//  UnAuthAccountDetails.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct UnAuthAccountDetails: Decodable {
    
    public var customerInfo: CustomerInfo
    public var addressLine: String
    public var street: String
    public var city: String
    public var state: String
    public var zipCode: String
    public var buildingNumber: String
    public var premiseNumber: String
    public var isResidential: Bool
    public var isPasswordProtected: Bool
    public var isGasOnly: Bool
    public var status: String
    public var accountStatusCode: String
    public var isFinaled: Bool
    public var serviceType: String
    public var isCutOutNonPay: Bool
    public var isCutOutIssued: Bool
    public var isCutOutDispatched: Bool
    public var serviceAgreementCount: Int
    public var isCashOnly: Bool
    public var isAutoPay: Bool
    public var revenueClassType: String?
    public var isAutoPayEligible: Bool
    public var isEBillEligible: Bool
    public var isEBillEnrollment: Bool
    public var isBudgetBill: Bool
    public var isBudgetBillEligible: Bool
    public var isNetMetering: Bool
    public var billingInfo: BillingInfo
    public var accountNumber: String?
    public var isAMIAccount: Bool?
    public var isRCDCapable: Bool?

    enum CodingKeys: String, CodingKey {
        
        case customerInfo = "CustomerInfo", addressLine, street, city, state, zipCode, buildingNumber, premiseNumber, isResidential, isPasswordProtected, isGasOnly, status, accountStatusCode, isFinaled, serviceType, isCutOutNonPay, isCutOutIssued, isCutOutDispatched, serviceAgreementCount, isCashOnly, isAutoPay, revenueClassType, isAutoPayEligible, isEBillEligible, isEBillEnrollment, isBudgetBill, isBudgetBillEligible, isNetMetering, billingInfo = "BillingInfo", accountNumber, isAMIAccount, isRCDCapable
    }
}
