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
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return dateFormatter.date(from: dateString)
}

enum AccountType {
    case Residential
    case Commercial
}

struct Account: Mappable, Equatable, Hashable {
    let accountNumber: String
    let address: String?
    
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        address = map.optionalFrom("address")
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
    
    let isBudgetBillEnrollment: Bool
    let isBudgetBillEligible: Bool
    
    let isEBillEnrollment: Bool
    let isEBillEligible:Bool
    
    let status: String?
    
    let isAutoPay: Bool
    let isBGEasy: Bool
    
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        address = map.optionalFrom("address")
        
        try customerInfo = map.from("CustomerInfo")
        try billingInfo = map.from("BillingInfo")
        
        isPasswordProtected = map.optionalFrom("isPasswordProtected") ?? false
        isBudgetBillEnrollment = map.optionalFrom("isBudgetBill") ?? false
        isBudgetBillEligible = map.optionalFrom("isBudgetBillEligible") ?? false
        isEBillEnrollment = map.optionalFrom("isEBillEnrollment") ?? false
        isEBillEligible = map.optionalFrom("isEBillEligible") ?? false
        
        status = map.optionalFrom("status")
        
        isAutoPay = map.optionalFrom("isAutoPay") ?? false
        isBGEasy = map.optionalFrom("isBGEasy") ?? false
    }
    
    var eBillEnrollStatus: EBillEnrollStatus {
        switch (isEBillEnrollment, isEBillEligible, status?.lowercased() == "Finaled".lowercased()) {
        case (_, _, true):
            return .finaled
        case (_, false, false):
            return .ineligible
        case (true, true, false):
            return .canUnenroll
        case (false, true, false):
            return .canEnroll
        }
    }
}

struct CustomerInfo: Mappable {
    
    let emailAddress: String?
    
    init(map: Mapper) throws {
        emailAddress = map.optionalFrom("emailAddress")
    }
}

struct BillingInfo: Mappable {
    let netDueAmount: Double?
    let pastDueAmount: Double?
    let lastPaymentAmount: Double?
    let pendingPaymentAmount: Double?
    let remainingBalanceDue: Double?
    let restorationAmount: Double?
    let amtDpaReinst: Double?
    let dueByDate: Date?
    let lastPaymentDate: Date?
    let disconnectNoticeArrears: Int
    let isDisconnectNotice: Bool
    let billDate: Date?
    
    init(map: Mapper) throws {
        netDueAmount = map.optionalFrom("netDueAmount")
        pastDueAmount = map.optionalFrom("pastDueAmount")
        lastPaymentAmount = map.optionalFrom("lastPaymentAmount")
        pendingPaymentAmount = map.optionalFrom("pendingPaymentAmount")
        remainingBalanceDue = map.optionalFrom("remainingBalanceDue")
        restorationAmount = map.optionalFrom("restorationAmount")
        amtDpaReinst = map.optionalFrom("amtDpaReinst")
        dueByDate = map.optionalFrom("dueByDate", transformation: extractDate)
        lastPaymentDate = map.optionalFrom("lastPaymentDate", transformation: extractDate)
        disconnectNoticeArrears = map.optionalFrom("disconnectNoticeArrears") ?? 0
        isDisconnectNotice = map.optionalFrom("isDisconnectNotice") ?? false
        billDate = map.optionalFrom("billDate", transformation: extractDate)
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
