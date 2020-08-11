//
//  Wallet.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit

public struct Wallet: Decodable {
    public var walletItems: [WalletItem]
    
    enum CodingKeys: String, CodingKey {
        case walletItems = "WalletItems"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.walletItems = try container.decode([WalletItem].self,
                                           forKey: .walletItems)
    }
}
