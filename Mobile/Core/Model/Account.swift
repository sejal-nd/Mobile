//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//


import Mapper

private func extractDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    return dateString.apiFormatDate
}

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
        
        currentPremise = isMultipremise ? premises[0] : nil 
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
    let SERInfo: SERInfo
    let premiseInfo: [Premise]
    
    let isPasswordProtected: Bool
    let hasElectricSupplier: Bool
    let isSingleBillOption: Bool
    let isDualBillOption: Bool
    let isCashOnly: Bool
    let isSupplier: Bool
    let isActiveSeverance: Bool
    let isHourlyPricing: Bool
    let isBGEControlGroup: Bool
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
        
        try SERInfo = map.from("SERInfo")
        if let controlGroupFlag = SERInfo.controlGroupFlag, controlGroupFlag.uppercased() == "CONTROL" {
            isBGEControlGroup = true
        } else {
            isBGEControlGroup = false
        }
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
        isLowIncome = map.optionalFrom("isLowIncome") ?? false
        isFinaled = map.optionalFrom("flagFinaled") ?? false
		
		isAMIAccount = map.optionalFrom("isAMIAccount") ?? false
        isResidential = map.optionalFrom("isResidential") ?? false
        
        releaseOfInformation = map.optionalFrom("releaseOfInformation")
        
        peakRewards = map.optionalFrom("peakRewards")
        zipCode = map.optionalFrom("zipCode")
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
}

struct SERInfo: Mappable {
    let controlGroupFlag: String?
    let eventResults: [SERResult]
    
    init(map: Mapper) throws {
        controlGroupFlag = map.optionalFrom("ControlGroupFlag")
        eventResults = map.optionalFrom("eventResults") ?? []
    }
}

struct SERResult: Mappable {
    let actualKWH: Double
    let baselineKWH: Double
    let eventStart: Date
    let eventEnd: Date
    let savingDollar: Double
    let savingKWH: Double
    
    init(map: Mapper) throws {
        try eventStart = map.from("eventStart", transformation: extractDate)
        try eventEnd = map.from("eventEnd", transformation: extractDate)
        
        if let actualString: String = map.optionalFrom("actualKWH"), let doubleVal = Double(actualString) {
            actualKWH = doubleVal
        } else {
            actualKWH = 0
        }
        
        if let baselineString: String = map.optionalFrom("baselineKWH"), let doubleVal = Double(baselineString) {
            baselineKWH = doubleVal
        } else {
            baselineKWH = 0
        }

        if let savingDollarString: String = map.optionalFrom("savingDollar"), let doubleVal = Double(savingDollarString) {
            savingDollar = doubleVal
        } else {
            savingDollar = 0
        }
        
        if let savingKWHString: String = map.optionalFrom("savingKWH"), let doubleVal = Double(savingKWHString) {
            savingKWH = doubleVal
        } else {
            savingKWH = 0
        }
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

struct PaymentItem: Mappable {
    
    enum PaymentStatus: String {
        case scheduled = "scheduled"
        case pending = "pending"
        case processing = "processing"
    }
    
    let amount: Double
    let date: Date?
    let status: PaymentStatus
    
    init(map: Mapper) throws {
        amount = try map.from("paymentAmount")
        
        status = try map.from("status") {
            guard let statusString = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: PaymentStatus.self)
            }
            guard let status = PaymentStatus(rawValue: statusString.lowercased()) else {
                throw MapperError.convertibleError(value: statusString, type: PaymentStatus.self)
            }
            return status
        }
        
        date = map.optionalFrom("paymentDate", transformation: extractDate)
        
        // Scheduled payments require dates
        guard status != .scheduled || date != nil else {
            throw MapperError.convertibleError(value: "paymentDate", type: PaymentStatus.self)
        }
        
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
    let convenienceFee: Double?
    let scheduledPayment: PaymentItem?
    let pendingPayments: [PaymentItem]
    let atReinstateFee: Double?
    let minPaymentAmount: Double?
    let maxPaymentAmount: Double?
    let minPaymentAmountACH: Double?
    let maxPaymentAmountACH: Double?
    let currentDueAmount: Double?
    let residentialFee: Double?
    let commercialFee: Double?
    let turnOffNoticeExtensionStatus: String?
    let turnOffNoticeExtendedDueDate: Date?
    let deliveryCharges: Double?
    let supplyCharges: Double?
    let taxesAndFees: Double?

    init(map: Mapper) throws {
		netDueAmount = map.optionalFrom("netDueAmount")
		pastDueAmount = map.optionalFrom("pastDueAmount")
		pastDueRemaining = map.optionalFrom("pastDueRemaining")
		lastPaymentAmount = map.optionalFrom("lastPaymentAmount")
		lastPaymentDate = map.optionalFrom("lastPaymentDate", transformation: extractDate)
        remainingBalanceDue = map.optionalFrom("remainingBalanceDue")
        restorationAmount = map.optionalFrom("restorationAmount")
        amtDpaReinst = map.optionalFrom("amtDpaReinst")
        dueByDate = map.optionalFrom("dueByDate", transformation: extractDate)
        disconnectNoticeArrears = map.optionalFrom("disconnectNoticeArrears")
        isDisconnectNotice = map.optionalFrom("isDisconnectNotice") ?? false
        billDate = map.optionalFrom("billDate", transformation: extractDate)
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
        turnOffNoticeExtendedDueDate = map.optionalFrom("turnOffNoticeExtendedDueDate", transformation: extractDate)
        deliveryCharges = map.optionalFrom("deliveryCharges")
        supplyCharges = map.optionalFrom("supplyCharges")
        taxesAndFees = map.optionalFrom("taxesAndFees")
        
        let paymentDicts: [NSDictionary]? = map.optionalFrom("payments") {
            guard let array = $0 as? [NSDictionary] else {
                throw MapperError.convertibleError(value: $0, type: Array<NSDictionary>.self)
            }
            return array
        }
        
        let paymentItems = paymentDicts?.flatMap(PaymentItem.from)
        
        scheduledPayment = paymentItems?.filter { $0.status == .scheduled }.last
        pendingPayments = paymentItems?
            .filter { $0.status == .pending || $0.status == .processing } ?? []
        
    }
    
    func convenienceFeeString(isComplete: Bool) -> String {
        var convenienceFeeStr = ""
        if isComplete {
            convenienceFeeStr = String(format: "A convenience fee will be applied to this payment. Residential accounts: %@. Business accounts: %@",
                                      residentialFee!.currencyString!, commercialFee!.percentString!)
        } else {
            convenienceFeeStr = String(format:"Fees: %@ Residential | %@ Business",
                                      residentialFee!.currencyString!, commercialFee!.percentString!)
        }
        return convenienceFeeStr
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
