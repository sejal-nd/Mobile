//
//  RecoverUsernameRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct RecoverUsernameRequest: Encodable {
    let phone: String
    let identifier: String?
    let accountNumber: String?
    let questionId: String
    let securityAnswer: String
    let cipherString: String
    
    enum CodingKeys: String, CodingKey {
        case phone
        case identifier
        case accountNumber = "account_number"
        case questionId = "question_id"
        case securityAnswer = "security_answer"
        case cipherString
    }
}
