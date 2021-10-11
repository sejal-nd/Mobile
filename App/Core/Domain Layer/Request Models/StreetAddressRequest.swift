//
//  StreetAddressRequest.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct StreetAddressRequest: Encodable{
    let address: String
    let zipcode: String
    let isFuzzySearch : Bool

    init(address: String, zipcode: String, isFuzzySearch: Bool) {
        self.address = address
        self.zipcode = zipcode
        self.isFuzzySearch = isFuzzySearch
    }

    enum CodingKeys: String, CodingKey {
        case address = "address"
        case zipcode = "zipcode"
        case isFuzzySearch = "isFuzzySearch"
    }

}
