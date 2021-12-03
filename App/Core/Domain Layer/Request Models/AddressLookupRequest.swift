//
//  AddressLookupRequest.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct AddressLookupRequest: Encodable{
    let address: String
    let zipcode: String
    let PremiseID : String

    init(address: String, zipcode: String, PremiseID: String) {
        self.address = address
        self.zipcode = zipcode
        self.PremiseID = PremiseID
    }

    enum CodingKeys: String, CodingKey {
        case address = "address"
        case zipcode = "zipcode"
        case PremiseID = "PremiseID"
    }

}
