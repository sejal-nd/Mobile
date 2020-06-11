//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewAccountDetails: Decodable {
    public var accountNumber: String
    public var address: String
    
    public var accountStatusCode: String?
    public var accountType: String
    public var accountNickname: String?
    public var isAMIAccount: Bool
    public var isModeledForOpower: Bool
    public var isCREligible: Bool
    public var isCutOut: Bool
    public var isCutOutNonPay: Bool
    public var isCutOutIssued: Bool
    public var isCutOutDispatched: Bool
    public var isDefaultProfile: Bool
    public var isDollarDonationsAccount: Bool
    public var isDueDateExtensionEligible: Bool
    public var isGasOnly: Bool
    public var isLowIncome: Bool
    public var isNonService: Bool
    public var isPTSAccount: Bool
    public var isPartialResult: Bool
    public var isPasswordProtected: Bool
    public var isCashOnly: Bool
    public var shouldReleaseInformation: Bool?
    public var revenueClass: Bool?
    public var serviceAgreementCount: Int
    public var isSmartEnergyRewardsEnrolled: Bool
    
    public var amountDue: String?
    public var dueDate: Date?
    public var serviceType: String
    public var status: String?
    
    
    public var billRouteType: String
    public var isNetMetering: Bool
    public var isEBillEligible: Bool
    public var activeSeverance: Bool = false
    public var isAutoPay: Bool
    public var isBudgetBill: Bool
    public var isSummaryBillingIneligible: Bool
    public var isEdiBilling: Bool
    public var isResidential: Bool
    public var isEBillEnrollment: Bool
    public var addressLine: String
    public var street: String
    public var city: String
    public var state: String
    public var zipCode: String
    public var buildingNumber: String
    public var premiseNumber: String
    public var amiAccountIdentifier: String
    public var amiCustomerIdentifier: String
    public var rateSchedule: String
    public var peakRewards: String
    public var isPeakRewards: Bool
    public var electricChoiceID: String
    public var isBudgetBillEligible: Bool
    public var budgetBillMessage: String?
    public var isAutoPayEligible: Bool
    public var customerNumber: String
    
    public var customerInfo: NewCustomerInfo
    public var premiseInfo: [NewPremiseInfo]

    enum CodingKeys: String, CodingKey {
        case accountNumber = "accountNumber"
        case address = "address"
        
        case accountStatusCode
        case accountType
        case accountNickname
        case isAMIAccount
        case isModeledForOpower
        case isCREligible
        case isCutOut
        case isCutOutNonPay
        case isCutOutIssued
        case isCutOutDispatched
        case isDefaultProfile
        case isDollarDonationsAccount
        case isDueDateExtensionEligible
        case isGasOnly
        case isLowIncome
        case isNonService
        case isPTSAccount
        case isPartialResult
        case isPasswordProtected
        case isCashOnly
        case shouldReleaseInformation = "releaseOfInformation"
        case revenueClass
        case serviceAgreementCount
        case isSmartEnergyRewardsEnrolled = "smartEnergyRewardsStatus"
        
        case amountDue
        case dueDate
        case serviceType
        case status
        
        case billRouteType
        case isNetMetering
        case isEBillEligible
        case activeSeverance
        case isAutoPay
        case isBudgetBill
        case isSummaryBillingIneligible
        case isEdiBilling
        case isResidential
        case isEBillEnrollment
        case addressLine
        case street
        case city
        case state
        case zipCode
        case buildingNumber
        case premiseNumber
        case amiAccountIdentifier
        case amiCustomerIdentifier
        case rateSchedule
        case peakRewards
        case isPeakRewards
        case electricChoiceID
        case isBudgetBillEligible
        case budgetBillMessage
        case isAutoPayEligible
        case customerNumber
        
        case customerInfo = "CustomerInfo"
        case premiseInfo = "PremiseInfo"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accountNumber = try container.decode(String.self,
                                             forKey: .accountNumber)
        self.address = try container.decode(String.self,
                                       forKey: .address)
        
        self.accountStatusCode = try container.decodeIfPresent(String.self,
                                                          forKey: .accountStatusCode)
        self.accountType = try container.decode(String.self,
                                           forKey: .accountType)
        self.accountNickname = try container.decodeIfPresent(String.self,
                                                        forKey: .accountNickname)
        self.isAMIAccount = try container.decode(Bool.self,
                                            forKey: .isAMIAccount)
        self.isModeledForOpower = try container.decode(Bool.self,
                                                  forKey: .isModeledForOpower)
        self.isCREligible = try container.decode(Bool.self,
                                            forKey: .isCREligible)
        self.isCutOut = try container.decode(Bool.self,
                                        forKey: .isCutOut)
        self.isCutOutNonPay = try container.decode(Bool.self,
                                              forKey: .isCutOutNonPay)
        self.isCutOutIssued = try container.decode(Bool.self,
                                              forKey: .isCutOutIssued)
        self.isCutOutDispatched = try container.decode(Bool.self,
                                                  forKey: .isCutOutDispatched)
        self.isDefaultProfile = try container.decode(Bool.self,
                                                forKey: .isDefaultProfile)
        self.isDollarDonationsAccount = try container.decode(Bool.self,
                                                        forKey: .isDollarDonationsAccount)
        self.isDueDateExtensionEligible = try container.decode(Bool.self,
                                                          forKey: .isDueDateExtensionEligible)
        self.isGasOnly = try container.decode(Bool.self,
                                         forKey: .isGasOnly)
        self.isLowIncome = try container.decode(Bool.self,
                                           forKey: .isLowIncome)
        self.isNonService = try container.decode(Bool.self,
                                            forKey: .isNonService)
        self.isPTSAccount = try container.decode(Bool.self,
                                            forKey: .isPTSAccount)
        self.isPartialResult = try container.decode(Bool.self,
                                               forKey: .isPartialResult)
        self.isPasswordProtected = try container.decode(Bool.self,
                                                   forKey: .isPasswordProtected)
        
        self.isCashOnly = try container.decode(Bool.self,
                                          forKey: .isCashOnly)
        self.shouldReleaseInformation = try container.decodeIfPresent(Bool.self,
                                                                 forKey: .shouldReleaseInformation)
        self.revenueClass = try container.decodeIfPresent(Bool.self,
                                                     forKey: .revenueClass)
        self.serviceAgreementCount = try container.decode(Int.self,
                                                     forKey: .serviceAgreementCount)
        self.isSmartEnergyRewardsEnrolled = try container.decode(Bool.self,
                                                            forKey: .isSmartEnergyRewardsEnrolled)
        self.amountDue = try container.decodeIfPresent(String.self,
                                                  forKey: .amountDue)
        self.dueDate = try container.decodeIfPresent(Date.self,
                                                forKey: .dueDate)
        self.serviceType = try container.decode(String.self,
                                           forKey: .serviceType)
        self.status = try container.decodeIfPresent(String.self,
                                               forKey: .status)
        
        
        self.billRouteType = try container.decode(String.self,
        forKey: .billRouteType)
        self.isNetMetering = try container.decode(Bool.self,
        forKey: .isNetMetering)
        self.isEBillEligible = try container.decode(Bool.self,
        forKey: .isEBillEligible)
        self.activeSeverance = try container.decodeIfPresent(Bool.self,
        forKey: .activeSeverance) ?? false
        self.isAutoPay = try container.decode(Bool.self,
        forKey: .isAutoPay)
        self.isBudgetBill = try container.decode(Bool.self,
        forKey: .isBudgetBill)
        self.isSummaryBillingIneligible = try container.decode(Bool.self,
        forKey: .isSummaryBillingIneligible)
        self.isEdiBilling = try container.decode(Bool.self,
        forKey: .isEdiBilling)
        self.isEBillEnrollment = try container.decode(Bool.self,
        forKey: .isEBillEnrollment)
        self.isResidential = try container.decode(Bool.self,
        forKey: .isResidential)
        self.addressLine = try container.decode(String.self,
        forKey: .addressLine)
        self.street = try container.decode(String.self,
        forKey: .street)
        self.city = try container.decode(String.self,
        forKey: .city)
        self.state = try container.decode(String.self,
        forKey: .state)
        self.zipCode = try container.decode(String.self,
        forKey: .zipCode)
        self.buildingNumber = try container.decode(String.self,
        forKey: .buildingNumber)
        self.premiseNumber = try container.decode(String.self,
        forKey: .premiseNumber)
        self.amiAccountIdentifier = try container.decode(String.self,
        forKey: .amiAccountIdentifier)
        self.amiCustomerIdentifier = try container.decode(String.self,
        forKey: .amiCustomerIdentifier)
        self.rateSchedule = try container.decode(String.self,
        forKey: .rateSchedule)
        self.peakRewards = try container.decode(String.self,
        forKey: .peakRewards)
        self.isPeakRewards = try container.decode(Bool.self,
        forKey: .isPeakRewards)
        self.electricChoiceID = try container.decode(String.self,
        forKey: .electricChoiceID)
        self.isBudgetBillEligible = try container.decode(Bool.self,
        forKey: .isBudgetBillEligible)
        self.budgetBillMessage = try container.decodeIfPresent(String.self,
        forKey: .budgetBillMessage)
        self.isAutoPayEligible = try container.decode(Bool.self,
        forKey: .isAutoPayEligible)
        self.customerNumber = try container.decode(String.self,
        forKey: .customerNumber)
        
        self.customerInfo = try container.decode(NewCustomerInfo.self,
                                            forKey: .customerInfo)
        self.premiseInfo = try container.decode([NewPremiseInfo].self,
        forKey: .premiseInfo)
    }
}
