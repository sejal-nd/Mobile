//
//  ValidateAccountRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// BROKEN
public struct ValidateAccountRequest: Encodable {
    var identifier: String = ""
    var phoneNumber: String = ""
    var accountNumber: String? = nil
    var billDate: String? = nil
    var amountDue: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case identifier = "identifier"
        case phoneNumber = "phone"
        case accountNumber = "account_num"
        case billDate = "bill_date"
        case amountDue = "amount_due"
    }
}
