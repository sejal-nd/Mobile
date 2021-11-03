//
//  DueDateEligibility.swift
//  EUMobile
//
//  Created by Adarsh Maurya on 21/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct DueDateElibility: Decodable {
    let isPaymentExtensionEligible: Bool?
    let extensionDueAmt: Double?
    let extendedDueDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case isPaymentExtensionEligible = "isPaymentExtensionEligible"
        case extensionDueAmt = "extensionDueAmt"
        case extendedDueDate = "extendedDueDate"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPaymentExtensionEligible = (try container.decodeIfPresent(Bool.self, forKey: .isPaymentExtensionEligible))
        extensionDueAmt = (try container.decodeIfPresent(Double.self, forKey: .extensionDueAmt))
        extendedDueDate = (try container.decodeIfPresent(Date.self, forKey: .extendedDueDate))
    }
}
