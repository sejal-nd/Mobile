//
//  NewAccountRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewAccountRequest: Encodable {
    let username: String
    let password: String
    let accountNum: String?
    let identifier: String
    let phone: String
    let question1: String
    let answer1: String
    let question2: String
    let answer2: String
    let question3: String
    let answer3: String
    let isPrimary: String
    let isEnrollEBill: String
}
