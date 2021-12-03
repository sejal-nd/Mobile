//
//  AppartmentRequest.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct AppartmentRequest: Encodable{
    let address: String
    let zipcode: String

    init(address: String, zipcode: String) {
        self.address = address
        self.zipcode = zipcode
    }

    enum CodingKeys: String, CodingKey {
        case address = "address"
        case zipcode = "zipcode"
    }

}
