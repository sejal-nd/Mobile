//
//  WalletRequest.swift
//  BGE
//
//  Created by Cody Dillon on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WalletRequest: Encodable {
    var billerId: String
    
    enum CodingKeys: String, CodingKey {
        case billerId = "biller_id"
    }
    
    public init(billerId: String? = nil) {
        self.billerId = billerId ?? AccountsStore.shared.billerID
    }
}
