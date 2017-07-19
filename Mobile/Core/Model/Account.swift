//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//


import Mapper

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    return dateString.apiFormatDate
}

enum AccountType {
    case Residential
    case Commercial
}

struct Account: Mappable, Equatable, Hashable {
    let accountNumber: String
    let address: String?
    var premises: Array<Premise> //TODO: return to let when testing is done
    var currentPremise: Premise?
    
    let status: String?
    let isLinked: Bool
    let isDefault: Bool
    let isFinaled: Bool
    //let isStopped: Bool // Not sure the status of this. Will BGE accounts just send `flagFinaled` or will it be different?
    
    init(map: Mapper) throws {
        accountNumber = try map.from("accountNumber")
        address = map.optionalFrom("address")
        premises = map.optionalFrom("PremiseInfo") ?? []
        
        status = map.optionalFrom("status")
        isLinked = map.optionalFrom("isLinkedProfile") ?? false
        isDefault = map.optionalFrom("isDefaultProfile") ?? false
        isFinaled = map.optionalFrom("flagFinaled") ?? false
        //isStopped = map.optionalFrom("isStoppedFlag") ?? false
        
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
    
    let releaseOfInformation: String?
	
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
        
        releaseOfInformation = map.optionalFrom("releaseOfInformation")
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

struct BillingInfo: Mappable {
    let netDueAmount: Double?
    let pastDueAmount: Double?
	let pastDueRemaining: Double?
	let lastPaymentAmount: Double?
	let lastPaymentDate: Date?
    let pendingPaymentAmount: Double?
    let remainingBalanceDue: Double?
    let restorationAmount: Double?
    let amtDpaReinst: Double?
    let dueByDate: Date?
    let disconnectNoticeArrears: Int
    let isDisconnectNotice: Bool
    let billDate: Date?
    let convenienceFee: Double?
    let scheduledPaymentAmount: Double?
    let scheduledPaymentDate: Date?
    let atReinstateFee: Double?
    let minPaymentAmount: Double?
    let maxPaymentAmount: Double?
    let minPaymentAmountACH: Double?
    let maxPaymentAmountACH: Double?
    let currentDueAmount: Double?
    
    init(map: Mapper) throws {
		netDueAmount = map.optionalFrom("netDueAmount")
		pastDueAmount = map.optionalFrom("pastDueAmount")
		pastDueRemaining = map.optionalFrom("pastDueRemaining")
		lastPaymentAmount = map.optionalFrom("lastPaymentAmount")
		lastPaymentDate = map.optionalFrom("lastPaymentDate", transformation: extractDate)
        pendingPaymentAmount = map.optionalFrom("pendingPaymentAmount")
        remainingBalanceDue = map.optionalFrom("remainingBalanceDue")
        restorationAmount = map.optionalFrom("restorationAmount")
        amtDpaReinst = map.optionalFrom("amtDpaReinst")
        dueByDate = map.optionalFrom("dueByDate", transformation: extractDate)
        disconnectNoticeArrears = map.optionalFrom("disconnectNoticeArrears") ?? 0
        isDisconnectNotice = map.optionalFrom("isDisconnectNotice") ?? false
        billDate = map.optionalFrom("billDate", transformation: extractDate)
        convenienceFee = map.optionalFrom("convenienceFee")
        scheduledPaymentAmount = map.optionalFrom("scheduledPaymentAmount")
        scheduledPaymentDate = map.optionalFrom("scheduledPaymentDate", transformation: extractDate)
        atReinstateFee = map.optionalFrom("atReinstateFee")
        minPaymentAmount = map.optionalFrom("minimumPaymentAmount")
        maxPaymentAmount = map.optionalFrom("maximumPaymentAmount")
        minPaymentAmountACH =  map.optionalFrom("minimumPaymentAmountACH")
        maxPaymentAmountACH = map.optionalFrom("maximumPaymentAmountACH")
        currentDueAmount = map.optionalFrom("currentDueAmount")
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
