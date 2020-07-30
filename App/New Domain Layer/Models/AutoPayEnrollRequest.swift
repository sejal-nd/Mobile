//
//  AutoPayEnrollRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 7/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AutoPayEnrollRequest: Encodable {
    
    let bankDetails: BankDetails
    let requestType: String
    
    init(nameOfAccount: String,
         bankAccountType: String,
         routingNumber: String,
         bankAccountNumber: String,
         isUpdate: Bool) {
        
        bankDetails = BankDetails(nameOfAccount: nameOfAccount, bankAccountType: bankAccountType, routingNumber: routingNumber, bankAccountNumber: bankAccountNumber)
        requestType = isUpdate ? "Update": "Start"
    }
    
    enum CodingKeys: String, CodingKey {
        case bankDetails = "bank_details"
        case requestType = "auto_pay_request_type"
    }
    
    var isUpdate: Bool {
        return requestType == "Update"
    }
}

struct BankDetails: Encodable {
    let nameOfAccount: String
    let bankAccountType: String
    let routingNumber: String
    let bankAccountNumber: String
    let bankName = "N/A"
    
    enum CodingKeys: String, CodingKey {
        case nameOfAccount = "name_on_account"
        case bankAccountType = "bank_account_type"
        case routingNumber = "routing_number"
        case bankAccountNumber = "bank_account_number"
        case bankName = "bank_name"
    }
}
