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
       
        do {
            try cipher = map.from("cipherString")
        } catch {
            cipher = ""
        }
        do {
            try questionId = map.from("question_id")
        } catch {
            questionId = 0
        }
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
