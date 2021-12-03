//
//  StreetAddressResponse.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct StreetAddressResponse : Decodable {
    var success: Bool? = false
    var data: [String?]

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case data = "data"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        data = try container.decodeIfPresent([String?].self, forKey: .data)!
    }
}
