//
//  PremiseIDResponse.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct AppartmentResponse: Decodable {
    let premiseID: String?
    let suiteNumber: String?
    enum CodingKeys: String, CodingKey {
        case premiseID = "premiseID"
        case suiteNumber = "suiteNumber"
    }
}
