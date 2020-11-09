//
//  WalletEncryptionKeyRequest.swift
//  BGE
//
//  Created by Cody Dillon on 8/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WalletEncryptionKeyRequest: Encodable {
    let pmCategory: String
    let postbackUrl: String
    let ownerId: String?
    let strParam: String
    let walletItemId: String?
    
    enum CodingKeys: String, CodingKey {
        case pmCategory
        case postbackUrl
        case ownerId
        case strParam
        case walletItemId = "wallet_item_id"
    }
}
