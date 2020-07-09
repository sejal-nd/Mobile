//
//  NewForgotMaskedUsername.swift
//  Mobile
//
//  Created by Cody Dillon on 4/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ForgotMaskedUsername: Decodable {
    let email: String?
    let question: String?
    let questionId: Int
    let cipher: String
    
    enum CodingKeys: String, CodingKey {
        case email
        case question
        case questionId = "question_id"
        case cipher
    }
}
