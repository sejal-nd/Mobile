//
//  AccountDetail.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountDetail: Decodable {
    public var accountNumber: String
    public var address: String?
    
    public var accountStatusCode: String?
    public var accountType: String?
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
    public var releaseOfInformation: String?
    public var revenueClass: String?
    public var serviceAgreementCount: Int
    public var isSmartEnergyRewardsEnrolled: Bool
    public var isPippEnrolled: Bool
    
    public var amountDue: String?
    public var dueDate: Date?
    public var serviceType: String?
    public var status: String?
    
    public var billRouteType: String
    public var isNetMetering: Bool
    public var isEBillEligible: Bool
    public var isAutoPay: Bool
    public var isBudgetBill: Bool
    public var isSummaryBillingIneligible: Bool
    public var isEdiBilling: Bool
    public var isResidential: Bool
    public var isFinaled: Bool
    public var isBGEasy: Bool
    public var isEBillEnrollment: Bool
    public var addressLine: String?
    public var street: String?
    public var city: String?
    public var state: String?
    public var zipCode: String?
    public var buildingNumber: String?
    public var premiseNumber: String?
    public var amiAccountIdentifier: String
    public var amiCustomerIdentifier: String
    public var rateSchedule: String?
    public var peakRewards: String?
    public var isPeakRewards: Bool
    public var electricChoiceID: String?
    public var gasChoiceID: String?
    public var utilityCode: String?
    public var isBudgetBillEligible: Bool
    public var budgetBillMessage: String?
    public var isAutoPayEligible: Bool
    public var customerNumber: String
    public var isHourlyPricing: Bool
    public var hasElectricSupplier: Bool
    public var isSingleBillOption: Bool
    public var isSupplier: Bool
    public var isActiveSeverance: Bool
    public var isDualBillOption: Bool
    // alert preference eligibility
    let isHUAEligible: Bool?
    let isPTREligible: Bool?
    let isPTSEligible: Bool?
    let isPESCEligible: Bool?
    let hasThirdPartySupplier: Bool
    
    let isEnergyWiseRewardsEligible: Bool
    let isEnergyWiseRewardsEnrolled: Bool
    
    let isPeakEnergySavingsCreditEligible: Bool
    let isPeakEnergySavingsCreditEnrolled: Bool
    
    let isOHEPEligible: Bool
    
    public var customerInfo: CustomerInfo
    let billingInfo: BillingInfo
    let serInfo: SERInfo
    public var premiseInfo: [PremiseInfo]
    
    // Only 3 real states to think about
    enum PrepaidStatus: String, Decodable {
        // Not Enrolled
        case inactive = "INACTIVE"
        case invited = "INVITED"
        case canceled = "CANCELED"
        case expired = "EXPIRED"
        // Pending
        case pending = "PENDING"
        // Enrolled
        case active = "ACTIVE"
    }
    
    let prepaidStatus: PrepaidStatus
    
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
        case releaseOfInformation
        case revenueClass
        case serviceAgreementCount
        case isSmartEnergyRewardsEnrolled = "smartEnergyRewardsStatus"
        case isPippEnrolled
        
        case amountDue
        case dueDate
        case serviceType
        case status
        
        case billRouteType
        case isNetMetering
        case isEBillEligible
        case isAutoPay
        case isBudgetBill
        case isSummaryBillingIneligible
        case isEdiBilling
        case isResidential
        case isFinaled = "flagFinaled"
        case isBGEasy
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
        case gasChoiceID
        case utilityCode
        case isBudgetBillEligible
        case budgetBillMessage
        case isAutoPayEligible
        case customerNumber
        case isHourlyPricing
        
        case customerInfo = "CustomerInfo"
        case billingInfo = "BillingInfo"
        case serInfo = "SERInfo"
        case premiseInfo = "PremiseInfo"
        case prepaidStatus = "prepaid_status"
        case hasThirdPartySupplier
        case isHUAEligible
        case isPTREligible
        case isPTSEligible
        case isPESCEligible
        case hasElectricSupplier
        case isSingleBillOption
        case isSupplier
        case isActiveSeverance = "activeSeverance"
        case isDualBillOption
        
        case isEnergyWiseRewardsEligible
        case isEnergyWiseRewardsEnrolled
        case isPeakEnergySavingsCreditEligible
        case isPeakEnergySavingsCreditEnrolled
        
        case isOHEPEligible
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accountNumber = try container.decode(String.self,
                                                  forKey: .accountNumber)
        self.address = try container.decodeIfPresent(String.self,
                                                     forKey: .address)
        
        self.accountStatusCode = try container.decodeIfPresent(String.self,
                                                               forKey: .accountStatusCode)
        self.accountType = try container.decodeIfPresent(String.self,
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
        self.releaseOfInformation = try container.decodeIfPresent(String.self,
                                                                  forKey: .releaseOfInformation)
        self.revenueClass = try container.decodeIfPresent(String.self,
                                                          forKey: .revenueClass)
        self.serviceAgreementCount = try container.decode(Int.self,
                                                          forKey: .serviceAgreementCount)
        self.isSmartEnergyRewardsEnrolled = try container.decode(Bool.self,
                                                                 forKey: .isSmartEnergyRewardsEnrolled)
        self.isPippEnrolled = try container.decodeIfPresent(Bool.self, forKey: .isPippEnrolled) ?? false
        self.amountDue = try container.decodeIfPresent(String.self,
                                                       forKey: .amountDue)
        self.dueDate = try container.decodeIfPresent(Date.self,
                                                     forKey: .dueDate)
        self.serviceType = try container.decodeIfPresent(String.self,
                                                         forKey: .serviceType)
        self.status = try container.decodeIfPresent(String.self,
                                                    forKey: .status)
        
        
        self.billRouteType = try container.decode(String.self,
                                                  forKey: .billRouteType)
        self.isNetMetering = try container.decodeIfPresent(Bool.self,
                                                           forKey: .isNetMetering) ?? false
        self.isEBillEligible = try container.decodeIfPresent(Bool.self,
                                                             forKey: .isEBillEligible) ?? false
        self.isAutoPay = try container.decodeIfPresent(Bool.self,
                                                       forKey: .isAutoPay) ?? false
        self.isBudgetBill = try container.decodeIfPresent(Bool.self,
                                                          forKey: .isBudgetBill) ?? false
        self.isSummaryBillingIneligible = try container.decodeIfPresent(Bool.self,
                                                                        forKey: .isSummaryBillingIneligible) ?? false
        self.isEdiBilling = try container.decodeIfPresent(Bool.self,
                                                          forKey: .isEdiBilling) ?? false
        self.isEBillEnrollment = try container.decodeIfPresent(Bool.self,
                                                               forKey: .isEBillEnrollment) ?? false
        self.isResidential = try container.decodeIfPresent(Bool.self,
                                                           forKey: .isResidential) ?? false
        self.isFinaled = try container.decodeIfPresent(Bool.self,
                                                       forKey: .isFinaled) ?? false
        self.isBGEasy = try container.decodeIfPresent(Bool.self,
                                                      forKey: .isBGEasy) ?? false
        self.addressLine = try container.decodeIfPresent(String.self,
                                                forKey: .addressLine)
        self.street = try container.decodeIfPresent(String.self,
                                           forKey: .street)
        self.city = try container.decodeIfPresent(String.self,
                                         forKey: .city)
        self.state = try container.decodeIfPresent(String.self,
                                          forKey: .state)
        self.zipCode = try container.decodeIfPresent(String.self,
                                                     forKey: .zipCode)
        self.buildingNumber = try container.decodeIfPresent(String.self,
                                                   forKey: .buildingNumber)
        self.premiseNumber = try container.decodeIfPresent(String.self,
                                                           forKey: .premiseNumber)
        AccountsStore.shared.premiseNumber = self.premiseNumber
        self.amiAccountIdentifier = try container.decode(String.self,
                                                         forKey: .amiAccountIdentifier)
        self.amiCustomerIdentifier = try container.decode(String.self,
                                                          forKey: .amiCustomerIdentifier)
        self.rateSchedule = try container.decodeIfPresent(String.self,
                                                 forKey: .rateSchedule)
        self.peakRewards = try container.decodeIfPresent(String.self,
                                                         forKey: .peakRewards)
        self.isPeakRewards = try container.decodeIfPresent(Bool.self,
                                                           forKey: .isPeakRewards) ?? false
        self.electricChoiceID = try container.decodeIfPresent(String.self,
                                                              forKey: .electricChoiceID)
        self.gasChoiceID = try container.decodeIfPresent(String.self,
                                                         forKey: .gasChoiceID)
        self.utilityCode = try container.decodeIfPresent(String.self,
                                                         forKey: .utilityCode)
        self.isBudgetBillEligible = try container.decodeIfPresent(Bool.self,
                                                                  forKey: .isBudgetBillEligible) ?? false
        self.budgetBillMessage = try container.decodeIfPresent(String.self,
                                                               forKey: .budgetBillMessage)
        self.isAutoPayEligible = try container.decodeIfPresent(Bool.self,
                                                               forKey: .isAutoPayEligible) ?? false
        self.customerNumber = try container.decode(String.self,
                                                   forKey: .customerNumber)
        
        self.isEnergyWiseRewardsEligible = try container.decodeIfPresent(Bool.self,
                                                                         forKey: .isEnergyWiseRewardsEligible) ?? false
        self.isEnergyWiseRewardsEnrolled = try container.decodeIfPresent(Bool.self,
                                                                         forKey: .isEnergyWiseRewardsEnrolled) ?? false
        self.isPeakEnergySavingsCreditEligible = try container.decodeIfPresent(Bool.self,
                                                                               forKey: .isPeakEnergySavingsCreditEligible) ?? false
        self.isPeakEnergySavingsCreditEnrolled = try container.decodeIfPresent(Bool.self,
                                                                               forKey: .isPeakEnergySavingsCreditEnrolled) ?? false
        
        self.isOHEPEligible = try container.decodeIfPresent(Bool.self, forKey: .isOHEPEligible) ?? false
        
        self.customerInfo = try container.decode(CustomerInfo.self,
                                                 forKey: .customerInfo)
        self.billingInfo = try container.decode(BillingInfo.self, forKey: .billingInfo)
        self.serInfo = try container.decode(SERInfo.self, forKey: .serInfo)
        self.premiseInfo = try container.decodeIfPresent([PremiseInfo].self,
                                                         forKey: .premiseInfo) ?? []
        self.isHourlyPricing = try container.decodeIfPresent(Bool.self, forKey: .isHourlyPricing) ?? false
        self.prepaidStatus = try container.decodeIfPresent(PrepaidStatus.self, forKey: .prepaidStatus) ?? .inactive
        self.isHUAEligible = try container.decodeIfPresent(Bool.self, forKey: .isHUAEligible)
        self.isPTREligible = try container.decodeIfPresent(Bool.self, forKey: .isPTREligible)
        self.isPTSEligible = try container.decodeIfPresent(Bool.self, forKey: .isPTSEligible)
        self.isPESCEligible = try container.decodeIfPresent(Bool.self, forKey: .isPESCEligible)
        self.hasThirdPartySupplier = try container.decodeIfPresent(Bool.self, forKey: .hasThirdPartySupplier) ?? false
        self.hasElectricSupplier = try container.decodeIfPresent(Bool.self, forKey: .hasElectricSupplier) ?? false
        self.isSingleBillOption = try container.decodeIfPresent(Bool.self, forKey: .isSingleBillOption) ?? false
        self.isSupplier = try container.decodeIfPresent(Bool.self, forKey: .isSupplier) ?? false
        self.isActiveSeverance = try container.decodeIfPresent(Bool.self, forKey: .isActiveSeverance) ?? false
        self.isDualBillOption = try container.decodeIfPresent(Bool.self, forKey: .isDualBillOption) ?? false
        
        if status?.lowercased() == "inactive" {
            isFinaled = true
        }
    }
    
    var isEligibleForUsageData: Bool {
        switch serviceType {
        case "GAS", "ELECTRIC", "GAS/ELECTRIC":
            return premiseNumber != nil && isResidential && !isBGEControlGroup && !isFinaled && prepaidStatus != .active
        default:
            return false
        }
    }
    
    // BGE only - Smart Energy Rewards enrollment status
    var isSERAccount: Bool {
        return premiseInfo.first?.smartEnergyRewards == "ENROLLED"
    }
    
    var isBGEControlGroup: Bool {
        return serInfo.controlGroupFlag?.uppercased() == "CONTROL"
    }
    
    var eBillEnrollStatus: EBillEnrollStatus {
        switch (isEBillEnrollment, isEBillEligible, status?.lowercased() == "finaled") {
        case (true, _, _):
            return .canUnenroll
        case (false, _, true):
            return .finaled
        case (false, false, false):
            return .ineligible
        case (false, true, false):
            return .canEnroll
        }
    }
    
    var opcoType: OpCo? {
        if Configuration.shared.opco.isPHI,
           let utilityCode = utilityCode {
            switch utilityCode {
            case "ACE":
                return .ace
            case "DPL":
                return .delmarva
            case "PEP":
                return .pepco
            default:
                return nil
            }
        }
       return nil
    }
    
    var subOpco: SubOpCo? {
        if opcoType == .pepco && state == "MD" {
            return .pepcoMaryland
        } else if opcoType == .pepco && state == "DC" {
            return .pepcoDC
        } else if opcoType == .delmarva && state == "MD" {
            return .delmarvaMaryland
        } else if opcoType == .delmarva && state == "DE" {
            return .delmarvaDelaware
        } else {
            return nil
        }
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
