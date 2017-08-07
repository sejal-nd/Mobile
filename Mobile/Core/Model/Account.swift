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
    
    guard let date = dateString.apiFormatDate as? Date else {
        throw MapperError.convertibleError(value: dateString, type: Date.self)
    }
    
    return date
}

struct Account: Mappable, Equatable, Hashable {
    let accountNumber: String
    let address: String?
    let premises: Array<Premise>
    var currentPremise: Premise?
    
    let status: String?
    let isLinked: Bool
    let isDefault: Bool
    let isFinaled: Bool
    let isResidential: Bool

    init(map: Mapper) throws {
        accountNumber = try map.from("accountNumber")
        address = map.optionalFrom("address")
        premises = map.optionalFrom("PremiseInfo") ?? []
        
        status = map.optionalFrom("status")
        isLinked = map.optionalFrom("isLinkedProfile") ?? false
        isDefault = map.optionalFrom("isDefaultProfile") ?? false
        isFinaled = map.optionalFrom("flagFinaled") ?? false
        isResidential = map.optionalFrom("isResidential") ?? false
        
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
    let address: String?
    
    let customerInfo: CustomerInfo
    let billingInfo: BillingInfo
    
    let isPasswordProtected: Bool
    let hasElectricSupplier: Bool
    let isSingleBillOption: Bool
    let isDualBillOption: Bool
    let isCashOnly: Bool
    let isSupplier: Bool
    let isActiveSeverance: Bool
    
    let isBudgetBillEnrollment: Bool
    let isBudgetBillEligible: Bool
    let budgetBillMessage: String?
    
    let isEBillEnrollment: Bool
    let isEBillEligible:Bool
    
    let status: String?
	
	let isAutoPay: Bool
	let isBGEasy: Bool
	let isAutoPayEligible: Bool
    let isCutOutNonPay: Bool
	
	let isAMICustomer: Bool
    let isResidential: Bool
    
    let releaseOfInformation: String?
    
    let peakRewards: String?
	
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        address = map.optionalFrom("address")
        
        try customerInfo = map.from("CustomerInfo")
        try billingInfo = map.from("BillingInfo")
        
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
        
        status = map.optionalFrom("status")
        
		isAutoPay = map.optionalFrom("isAutoPay") ?? false
        isBGEasy = map.optionalFrom("isBGEasy") ?? false
		isAutoPayEligible = map.optionalFrom("isAutoPayEligible") ?? false
		isCutOutNonPay = map.optionalFrom("isCutOutNonPay") ?? false
		
		isAMICustomer = map.optionalFrom("isAMICustomer") ?? false
        isResidential = map.optionalFrom("isResidential") ?? false
        
        releaseOfInformation = map.optionalFrom("releaseOfInformation")
        
        peakRewards = map.optionalFrom("peakRewards")
    }
	
    var eBillEnrollStatus: EBillEnrollStatus {
		switch (isEBillEnrollment, isEBillEligible, status?.lowercased() == "Finaled".lowercased()) {
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
    let date: Date
    let status: PaymentStatus
    
    init(map: Mapper) throws {
        amount = try map.from("paymentAmount")
        date = try map.from("paymentDate", transformation: extractDate)
        status = try map.from("status") {
            guard let statusString = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: PaymentStatus.self)
            }
            guard let status = PaymentStatus(rawValue: statusString.lowercased()) else {
                throw MapperError.convertibleError(value: statusString, type: PaymentStatus.self)
            }
            return status
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
        convenienceFee = map.optionalFrom("convenienceFee")
        atReinstateFee = map.optionalFrom("atReinstateFee")
        minPaymentAmount = map.optionalFrom("minimumPaymentAmount")
        maxPaymentAmount = map.optionalFrom("maximumPaymentAmount")
        minPaymentAmountACH =  map.optionalFrom("minimumPaymentAmountACH")
        maxPaymentAmountACH = map.optionalFrom("maximumPaymentAmountACH")
        currentDueAmount = map.optionalFrom("currentDueAmount")
        residentialFee = map.optionalFrom("feeResidential")
        commercialFee = map.optionalFrom("feeCommercial")
        
        let paymentDicts: [NSDictionary] = try map.from("payments") {
            guard let array = $0 as? [NSDictionary] else {
                throw MapperError.convertibleError(value: $0, type: Array<NSDictionary>.self)
            }
            return array
        }
        
        let paymentItems = paymentDicts.flatMap(PaymentItem.from)
        
        scheduledPayment = paymentItems.first(where: { $0.status == .scheduled })
        pendingPayments = paymentItems.filter { $0.status == .pending || $0.status == .processing }.sorted {
            $0.date < $1.date
        }
    }
    
    func convenienceFeeString(isComplete: Bool) -> String {
        var conveienceFeeStr = ""
        if isComplete {
            conveienceFeeStr = String(format: "A convenience fee will be applied by Western Union Speedpay, our payment partner.\nResidential accounts: %@. Business accounts: %@",
                                      residentialFee!.currencyString!, commercialFee!.percentString!)
        } else {
            conveienceFeeStr = String(format:"Fees: %@ Residential | %@ Business",
                                      residentialFee!.currencyString!, commercialFee!.percentString!)
        }
        return conveienceFeeStr
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
