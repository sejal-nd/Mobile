//
//  AutoPayUnenrollRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 7/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AutoPayUnenrollRequest: Encodable {
    let confirmationNumber: String?
    
    let reason: String?
    let comments: String?
    
    init(confirmationNumber: String) {
        self.confirmationNumber = confirmationNumber
        self.reason = nil
        self.comments = nil
    }
    
    init(reason: String, comments: String? = "") {
        self.reason = reason
        self.comments = comments
        self.confirmationNumber = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case confirmationNumber = "confirmation_number"
        case reason
        case comments
    }
}
