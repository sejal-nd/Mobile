//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum AccountType {
    case Residential
    case Commercial
}

struct Account: Mappable, Equatable, Hashable {
    let accountType: AccountType
    let accountNumber: String
    let address: String?
    
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        address = map.optionalFrom("address")
        
        accountType = .Residential
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
    let emailAddress: String?
    let address: String?
    
    let isPasswordProtected: Bool
    
    let isBudgetBillEnrollment: Bool
    let isBudgetBillEligible: Bool
    
    let isEBillEnrollment: Bool
    let isEBillEligible:Bool
    
    let status: String?
    
    var eBillEnrollStatus: EBillEnrollStatus {
        switch (isEBillEnrollment, isEBillEligible, status == "Finaled") {
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
    
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        emailAddress = map.optionalFrom("emailAddress")
        address = map.optionalFrom("address")
        
        do {
            try isPasswordProtected = map.from("isPasswordProtected")
        } catch {
            isPasswordProtected = false
        }
        
        do {
            try isBudgetBillEnrollment = map.from("isBudgetBill")
        } catch {
            isBudgetBillEnrollment = false
        }
        do {
            try isBudgetBillEligible = map.from("isBudgetBillEligible")
        } catch {
            isBudgetBillEligible = false
        }
        
        do {
            try isEBillEnrollment = map.from("isEBillEnrollment")
        } catch {
            isEBillEnrollment = false
        }
        do {
            try isEBillEligible = map.from("isEBillEligible")
        } catch {
            isEBillEligible = false
        }
        
        status = map.optionalFrom("status")
    }
}

enum EBillEnrollStatus {
    case canEnroll, canUnenroll, finaled, ineligible
}
