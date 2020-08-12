//
//  BankName.swift
//  BGE
//
//  Created by Cody Dillon on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BankName: Decodable {
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case value = "BankName"
    }
}
