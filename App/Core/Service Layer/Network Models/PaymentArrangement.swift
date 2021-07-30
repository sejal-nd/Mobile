//
//  PaymentArrangement.swift
//  Mobile
//
//  Created by Adarsh Maurya on 21/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct PaymentArrangement: Decodable {
    let customerInfo: CustomerInfoModel?
    
    enum CodingKeys: String, CodingKey {
        case customerInfo = "customerInfo"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customerInfo = (try container.decodeIfPresent(CustomerInfoModel.self, forKey: .customerInfo))
    }
}

struct CustomerInfoModel: Decodable {
    let paEligibility: String?
    
    enum CodingKeys: String, CodingKey {
        case paEligibility = "PAEligibility"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paEligibility = (try container.decodeIfPresent(String.self, forKey: .paEligibility))
    }
}
