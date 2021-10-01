//
//  ValidatedZipCodeResponse.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
struct ValidatedZipCodeResponse: Decodable {

    var success: Bool? = false
    var multipleCustomers: Bool? = false
    var data: Data?

    struct Data: Decodable {
        let key: String
        let value: Bool
        enum CodingKeys: String, CodingKey {
            case key, value
        }
    }

    enum CodingKeys: String, CodingKey {
        case success = "success"
        case data = "data"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(Data.self, forKey: .data)
    }
}
