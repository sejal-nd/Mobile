//
//  AccountRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountRequest: Encodable {
    let firstName: String
    let lastName: String
    let nickName: String
    let username: String
    let password: String
    let accountNumber: String?
    let identifier: String
    let phone: String
    let question1: String
    let answer1: String
    let question2: String
    let answer2: String
    let question3: String
    let answer3: String
    let isPrimary: String
    let shouldEnrollEbill: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "FirstName"
        case lastName = "LastName"
        case nickName = "nickname"
        case username
        case password
        case accountNumber = "account_num"
        case identifier
        case phone
        case question1
        case answer1
        case question2
        case answer2
        case question3
        case answer3
        case isPrimary
        case shouldEnrollEbill = "enroll_ebill"
    }
}
