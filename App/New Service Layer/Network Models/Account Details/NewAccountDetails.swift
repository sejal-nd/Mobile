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
    public var activeSeverance: Bool
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
        case data = "data"
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
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.accountNumber = try data.decode(String.self,
                                             forKey: .accountNumber)
        self.address = try data.decode(String.self,
                                       forKey: .address)
        
        self.accountStatusCode = try data.decodeIfPresent(String.self,
                                                          forKey: .accountStatusCode)
        self.accountType = try data.decode(String.self,
                                           forKey: .accountType)
        self.accountNickname = try data.decodeIfPresent(String.self,
                                                        forKey: .accountNickname)
        self.isAMIAccount = try data.decode(Bool.self,
                                            forKey: .isAMIAccount)
        self.isModeledForOpower = try data.decode(Bool.self,
                                                  forKey: .isModeledForOpower)
        self.isCREligible = try data.decode(Bool.self,
                                            forKey: .isCREligible)
        self.isCutOut = try data.decode(Bool.self,
                                        forKey: .isCutOut)
        self.isCutOutNonPay = try data.decode(Bool.self,
                                              forKey: .isCutOutNonPay)
        self.isCutOutIssued = try data.decode(Bool.self,
                                              forKey: .isCutOutIssued)
        self.isCutOutDispatched = try data.decode(Bool.self,
                                                  forKey: .isCutOutDispatched)
        self.isDefaultProfile = try data.decode(Bool.self,
                                                forKey: .isDefaultProfile)
        self.isDollarDonationsAccount = try data.decode(Bool.self,
                                                        forKey: .isDollarDonationsAccount)
        self.isDueDateExtensionEligible = try data.decode(Bool.self,
                                                          forKey: .isDueDateExtensionEligible)
        self.isGasOnly = try data.decode(Bool.self,
                                         forKey: .isGasOnly)
        self.isLowIncome = try data.decode(Bool.self,
                                           forKey: .isLowIncome)
        self.isNonService = try data.decode(Bool.self,
                                            forKey: .isNonService)
        self.isPTSAccount = try data.decode(Bool.self,
                                            forKey: .isPTSAccount)
        self.isPartialResult = try data.decode(Bool.self,
                                               forKey: .isPartialResult)
        self.isPasswordProtected = try data.decode(Bool.self,
                                                   forKey: .isPasswordProtected)
        
        self.isCashOnly = try data.decode(Bool.self,
                                          forKey: .isCashOnly)
        self.shouldReleaseInformation = try data.decodeIfPresent(Bool.self,
                                                                 forKey: .shouldReleaseInformation)
        self.revenueClass = try data.decodeIfPresent(Bool.self,
                                                     forKey: .revenueClass)
        self.serviceAgreementCount = try data.decode(Int.self,
                                                     forKey: .serviceAgreementCount)
        self.isSmartEnergyRewardsEnrolled = try data.decode(Bool.self,
                                                            forKey: .isSmartEnergyRewardsEnrolled)
        self.amountDue = try data.decodeIfPresent(String.self,
                                                  forKey: .amountDue)
        self.dueDate = try data.decodeIfPresent(Date.self,
                                                forKey: .dueDate)
        self.serviceType = try data.decode(String.self,
                                           forKey: .serviceType)
        self.status = try data.decodeIfPresent(String.self,
                                               forKey: .status)
        
        
        self.billRouteType = try data.decode(String.self,
        forKey: .billRouteType)
        self.isNetMetering = try data.decode(Bool.self,
        forKey: .isNetMetering)
        self.isEBillEligible = try data.decode(Bool.self,
        forKey: .isEBillEligible)
        self.activeSeverance = try data.decode(Bool.self,
        forKey: .activeSeverance)
        self.isAutoPay = try data.decode(Bool.self,
        forKey: .isAutoPay)
        self.isBudgetBill = try data.decode(Bool.self,
        forKey: .isBudgetBill)
        self.isSummaryBillingIneligible = try data.decode(Bool.self,
        forKey: .isSummaryBillingIneligible)
        self.isEdiBilling = try data.decode(Bool.self,
        forKey: .isEdiBilling)
        self.isEBillEnrollment = try data.decode(Bool.self,
        forKey: .isEBillEnrollment)
        self.isResidential = try data.decode(Bool.self,
        forKey: .isResidential)
        self.addressLine = try data.decode(String.self,
        forKey: .addressLine)
        self.street = try data.decode(String.self,
        forKey: .street)
        self.city = try data.decode(String.self,
        forKey: .city)
        self.state = try data.decode(String.self,
        forKey: .state)
        self.zipCode = try data.decode(String.self,
        forKey: .zipCode)
        self.buildingNumber = try data.decode(String.self,
        forKey: .buildingNumber)
        self.premiseNumber = try data.decode(String.self,
        forKey: .premiseNumber)
        self.amiAccountIdentifier = try data.decode(String.self,
        forKey: .amiAccountIdentifier)
        self.amiCustomerIdentifier = try data.decode(String.self,
        forKey: .amiCustomerIdentifier)
        self.rateSchedule = try data.decode(String.self,
        forKey: .rateSchedule)
        self.peakRewards = try data.decode(String.self,
        forKey: .peakRewards)
        self.isPeakRewards = try data.decode(Bool.self,
        forKey: .isPeakRewards)
        self.electricChoiceID = try data.decode(String.self,
        forKey: .electricChoiceID)
        self.isBudgetBillEligible = try data.decode(Bool.self,
        forKey: .isBudgetBillEligible)
        self.budgetBillMessage = try data.decodeIfPresent(String.self,
        forKey: .budgetBillMessage)
        self.isAutoPayEligible = try data.decode(Bool.self,
        forKey: .isAutoPayEligible)
        self.customerNumber = try data.decode(String.self,
        forKey: .customerNumber)
        
        self.customerInfo = try data.decode(NewCustomerInfo.self,
                                            forKey: .customerInfo)
        self.premiseInfo = try data.decode([NewPremiseInfo].self,
        forKey: .premiseInfo)
    }
}
