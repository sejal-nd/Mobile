//
//  ForgotUsername.swift
//  Mobile
//
//  Created by Marc Shilling on 4/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct ForgotUsernameMasked: Mappable {
    let email: String?
    let question: String?
    let questionId: Int
    let cipher: String
    
    init(map: Mapper) throws {
        email = map.optionalFrom("email")
        question = map.optionalFrom("question")
        cipher = map.optionalFrom("cipherString") ?? ""
        questionId = map.optionalFrom("question_id") ?? 0
    }
}

struct AccountLookupResult: Mappable {
    let accountNumber: String?
    let streetNumber: String?
    let unitNumber: String?
    
    init(map: Mapper) throws {
        accountNumber = map.optionalFrom("AccountNumber")
        streetNumber = map.optionalFrom("StreetNumber")
        unitNumber = map.optionalFrom("ApartmentUnitNumber")
    }
}
