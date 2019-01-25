//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct Account: Mappable, Equatable, Hashable {
    let accountNumber: String
    let address: String?
    let premises: [Premise]
    var currentPremise: Premise?
    
    let status: String?
    let isLinked: Bool
    let isDefault: Bool
    let isFinaled: Bool
    let isResidential: Bool
    let serviceType: String?
    
    let isPasswordProtected: Bool

    init(map: Mapper) throws {
        accountNumber = try map.from("accountNumber")
        address = map.optionalFrom("address")
        premises = map.optionalFrom("PremiseInfo") ?? []
        
        status = map.optionalFrom("status")
        isLinked = map.optionalFrom("isLinkedProfile") ?? false
        isDefault = map.optionalFrom("isDefaultProfile") ?? false
        isFinaled = map.optionalFrom("flagFinaled") ?? false
        isResidential = map.optionalFrom("isResidential") ?? false
        serviceType = map.optionalFrom("serviceType")
        
        isPasswordProtected = map.optionalFrom("isPasswordProtected") ?? false
        
        currentPremise = premises.first
    }
    
    var isMultipremise: Bool{
        return premises.count > 1 //TODO: could be 0 depending on whether each account has matching default premise
    }
    
    // Equatable
    static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.accountNumber == rhs.accountNumber
    }
    
    // Hashable
    var hashValue: Int {
        return accountNumber.hash
    }
}

struct AccountDetail: Mappable {
    let accountNumber: String
    let premiseNumber: String?
    let address: String?
    
    let serviceType: String?
    
    let customerInfo: CustomerInfo
    let billingInfo: BillingInfo
    let serInfo: SERInfo
    let premiseInfo: [Premise]
    
    let isModeledForOpower: Bool
    let isPasswordProtected: Bool
    let hasElectricSupplier: Bool
    let isSingleBillOption: Bool
    let isDualBillOption: Bool
    let isCashOnly: Bool
    let isSupplier: Bool
    let isActiveSeverance: Bool
    let isHourlyPricing: Bool
    let isPTSAccount: Bool // ComEd only - Peak Time Savings enrollment status
    let isSERAccount: Bool // BGE only - Smart Energy Rewards enrollment status

    let isBudgetBillEnrollment: Bool
    let isBudgetBillEligible: Bool
    let budgetBillMessage: String?
    
    let isEBillEnrollment: Bool
    let isEBillEligible: Bool
    
    let status: String?
	
	let isAutoPay: Bool
	let isBGEasy: Bool
	let isAutoPayEligible: Bool
    let isCutOutNonPay: Bool
    let isCutOutIssued: Bool
    let isLowIncome: Bool
    let isFinaled: Bool
	
	let isAMIAccount: Bool
    let isResidential: Bool
    
    let releaseOfInformation: String?
    
    let peakRewards: String?
    let zipCode: String?

    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        premiseNumber = map.optionalFrom("premiseNumber")
        address = map.optionalFrom("address")
        
        serviceType = map.optionalFrom("serviceType")
        
        try customerInfo = map.from("CustomerInfo")
        try billingInfo = map.from("BillingInfo")
        
        try serInfo = map.from("SERInfo")
        isPTSAccount = map.optionalFrom("isPTSAccount") ?? false
        
        premiseInfo = map.optionalFrom("PremiseInfo") ?? []
        if !premiseInfo.isEmpty {
            let premise = premiseInfo[0]
            if let smartEnergyRewards = premise.smartEnergyRewards, smartEnergyRewards == "ENROLLED" {
                isSERAccount = true
            } else {
                isSERAccount = false
            }
        } else {
            isSERAccount = false
        }
        
        isModeledForOpower = map.optionalFrom("isModeledForOpower") ?? false
        isPasswordProtected = map.optionalFrom("isPasswordProtected") ?? false
        isBudgetBillEnrollment = map.optionalFrom("isBudgetBill") ?? false
        isBudgetBillEligible = map.optionalFrom("isBudgetBillEligible") ?? false
        budgetBillMessage = map.optionalFrom("budgetBillMessage")
        isEBillEnrollment = map.optionalFrom("isEBillEnrollment") ?? false
        isEBillEligible = map.optionalFrom("isEBillEligible") ?? false
        hasElectricSupplier = map.optionalFrom("hasElectricSupplier") ?? false
        isSingleBillOption = map.optionalFrom("isSingleBillOption") ?? false
        isDualBillOption = map.optionalFrom("isDualBillOption") ?? false
        isCashOnly = map.optionalFrom("isCashOnly") ?? false
        isSupplier = map.optionalFrom("isSupplier") ?? false
        isActiveSeverance = map.optionalFrom("activeSeverance") ?? false
        isHourlyPricing = map.optionalFrom("isHourlyPricing") ?? false

        status = map.optionalFrom("status")
        
		isAutoPay = map.optionalFrom("isAutoPay") ?? false
        isBGEasy = map.optionalFrom("isBGEasy") ?? false
		isAutoPayEligible = map.optionalFrom("isAutoPayEligible") ?? false
        isCutOutNonPay = map.optionalFrom("isCutOutNonPay") ?? false
        isCutOutIssued = map.optionalFrom("isCutOutIssued") ?? false
        isLowIncome = map.optionalFrom("isLowIncome") ?? false
        isFinaled = map.optionalFrom("flagFinaled") ?? false
		
		isAMIAccount = map.optionalFrom("isAMIAccount") ?? false
        isResidential = map.optionalFrom("isResidential") ?? false
        
        releaseOfInformation = map.optionalFrom("releaseOfInformation")
        
        peakRewards = map.optionalFrom("peakRewards")
        zipCode = map.optionalFrom("zipCode")
    }
    
    var isBGEControlGroup: Bool {
        return serInfo.controlGroupFlag?.uppercased() == "CONTROL"
    }
    
    /* TODO: When BGE is on Paymentus, move these 2 functions into BillingInfo, and
     * make minPaymentAmount, maxPaymentAmount, minPaymentAmountACH, maxPaymentAmountACH
     * private lets to enforce the use of only these functions. We can't do that currently
     * because our switch in maxPaymentAmount() relies on isResidential
     */
    func minPaymentAmount(bankOrCard: BankOrCard) -> Double {
        // Task 86747 - Use only hardcoded amounts until epay R2
        /*
         switch bankOrCard {
         case .bank:
         if let minPaymentAmount = billingInfo.minPaymentAmountACH {
         return minPaymentAmount
         }
         case .card:
         if let minPaymentAmount = billingInfo.minPaymentAmount {
         return minPaymentAmount
         }
         }
         */
        
        //TODO: Just return 5 once BGE switches to Paymentus
        switch Environment.shared.opco {
        case .bge:
            return 0.01
        case .comEd, .peco:
            return 5
        }
    }
    
    func maxPaymentAmount(bankOrCard: BankOrCard) -> Double {
        // Task 86747 - Use only hardcoded amounts until epay R2
        /*
         switch bankOrCard {
         case .bank:
         if let maxPaymentAmount = billingInfo.maxPaymentAmountACH {
         return maxPaymentAmount
         }
         case .card:
         if let maxPaymentAmount = billingInfo.maxPaymentAmount {
         return maxPaymentAmount
         }
         }
         */
        
        //: TODO - Simplify this switch to just bankOrCard when BGE switches to Paymentus
        switch (bankOrCard, Environment.shared.opco, isResidential) {
        case (.bank, .bge, true):
            return 99_999.99
        case (.bank, .bge, false):
            return 999_999.99
        case (.card, .bge, true):
            return 600
        case (.card, .bge, false):
            return 25000
            
        case (.bank, _, _):
            return 100_000
        case (.card, _, _):
            return 5000
        }
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
    
    var isEligibleForUsageData: Bool {
        switch serviceType {
        case "GAS", "ELECTRIC", "GAS/ELECTRIC":
            return premiseNumber != nil && isResidential && !isBGEControlGroup && !isFinaled
        default:
            return false
        }
    }
}

struct SERInfo: Mappable {
    let controlGroupFlag: String?
    let eventResults: [SERResult]
    
    init(map: Mapper) throws {
        controlGroupFlag = map.optionalFrom("ControlGroupFlag")
        eventResults = map.optionalFrom("eventResults") ?? []
    }
}

struct CustomerInfo: Mappable {
    
    let emailAddress: String?
    let number: String?
    let firstName: String?
    let nameCompressed: String?
    
    init(map: Mapper) throws {
        emailAddress = map.optionalFrom("emailAddress")
        number = map.optionalFrom("number")
        firstName = map.optionalFrom("firstName")
        nameCompressed = map.optionalFrom("nameCompressed")
    }
}

struct BillingInfo: Mappable {
    let netDueAmount: Double?
    let pastDueAmount: Double?
	let pastDueRemaining: Double?
	let lastPaymentAmount: Double?
	let lastPaymentDate: Date?
    let remainingBalanceDue: Double?
    let restorationAmount: Double?
    let amtDpaReinst: Double?
    let dueByDate: Date?
    let disconnectNoticeArrears: Double?
    let isDisconnectNotice: Bool
    let billDate: Date?
    let convenienceFee: Double? // ComEd/PECO use this
    let scheduledPayment: PaymentItem?
    let pendingPayments: [PaymentItem]
    let atReinstateFee: Double?
    let minPaymentAmount: Double?
    let maxPaymentAmount: Double?
    let minPaymentAmountACH: Double?
    let maxPaymentAmountACH: Double?
    let currentDueAmount: Double?
    let residentialFee: Double? // BGE uses this and
    let commercialFee: Double? // this
    let turnOffNoticeExtensionStatus: String?
    let turnOffNoticeExtendedDueDate: Date?
    let turnOffNoticeDueDate: Date?
    let deliveryCharges: Double?
    let supplyCharges: Double?
    let taxesAndFees: Double?

    init(map: Mapper) throws {
		netDueAmount = map.optionalFrom("netDueAmount")
		pastDueAmount = map.optionalFrom("pastDueAmount")
		pastDueRemaining = map.optionalFrom("pastDueRemaining")
		lastPaymentAmount = map.optionalFrom("lastPaymentAmount")
		lastPaymentDate = map.optionalFrom("lastPaymentDate", transformation: DateParser().extractDate)
        remainingBalanceDue = map.optionalFrom("remainingBalanceDue")
        restorationAmount = map.optionalFrom("restorationAmount")
        amtDpaReinst = map.optionalFrom("amtDpaReinst")
        dueByDate = map.optionalFrom("dueByDate", transformation: DateParser().extractDate)
        disconnectNoticeArrears = map.optionalFrom("disconnectNoticeArrears")
        isDisconnectNotice = map.optionalFrom("isDisconnectNotice") ?? false
        billDate = map.optionalFrom("billDate", transformation: DateParser().extractDate)
        atReinstateFee = map.optionalFrom("atReinstateFee")
        minPaymentAmount = map.optionalFrom("minimumPaymentAmount")
        maxPaymentAmount = map.optionalFrom("maximumPaymentAmount")
        minPaymentAmountACH =  map.optionalFrom("minimumPaymentAmountACH")
        maxPaymentAmountACH = map.optionalFrom("maximumPaymentAmountACH")
        currentDueAmount = map.optionalFrom("currentDueAmount")
        convenienceFee = map.optionalFrom("convenienceFee")
        residentialFee = map.optionalFrom("feeResidential")
        commercialFee = map.optionalFrom("feeCommercial")
        turnOffNoticeExtensionStatus = map.optionalFrom("turnOffNoticeExtensionStatus")
        turnOffNoticeExtendedDueDate = map.optionalFrom("turnOffNoticeExtendedDueDate", transformation: DateParser().extractDate)
        turnOffNoticeDueDate = map.optionalFrom("turnOffNoticeDueDate", transformation: DateParser().extractDate)
        deliveryCharges = map.optionalFrom("deliveryCharges")
        supplyCharges = map.optionalFrom("supplyCharges")
        taxesAndFees = map.optionalFrom("taxesAndFees")
        
        let paymentDicts: [NSDictionary]? = map.optionalFrom("payments") {
            guard let array = $0 as? [NSDictionary] else {
                throw MapperError.convertibleError(value: $0, type: Array<NSDictionary>.self)
            }
            return array
        }

        let paymentItems = paymentDicts?.compactMap(PaymentItem.from)

        scheduledPayment = paymentItems?.filter { $0.status == .scheduled }.last
        pendingPayments = paymentItems?
            .filter { $0.status == .pending || $0.status == .processing } ?? []
        
    }
    
    var pendingPaymentsTotal: Double {
        return pendingPayments.map(\.amount).reduce(0, +)
    }
    
    func convenienceFeeString(isComplete: Bool) -> String {
        var convenienceFeeStr = ""
        if isComplete {
            convenienceFeeStr = String(format: "A convenience fee will be applied to this payment. Residential accounts: %@. Business accounts: %@.",
                                      residentialFee!.currencyString, commercialFee!.percentString!)
        } else {
            convenienceFeeStr = String(format:"Fees: %@ Residential | %@ Business",
                                      residentialFee!.currencyString, commercialFee!.percentString!)
        }
        return convenienceFeeStr
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
