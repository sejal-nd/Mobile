//
//  NewWallet.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewWallet: Decodable {
    public var walletItems: [NewWalletItem]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case walletItems = "WalletItems"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.walletItems = try data.decode([NewWalletItem].self,
                                           forKey: .walletItems)
    }
}

public struct NewWalletItem: Decodable {
    public var id: String
    public var maskedAccountNumber: String
    public var categoryType: String
    public var methodType: String
    public var bankName: String?
    public var isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "walletItemID"
        case maskedAccountNumber = "maskedWalletItemAccountNumber"
        case categoryType = "paymentCategoryType"
        case methodType = "paymentMethodType"
        case bankName = "bankName"
        case isDefault = "isDefault"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self,
                                       forKey: .id)
        self.maskedAccountNumber = try container.decode(String.self,
                                                        forKey: .maskedAccountNumber)
        self.categoryType = try container.decode(String.self,
                                                 forKey: .categoryType)
        self.methodType = try container.decode(String.self,
                                               forKey: .methodType)
        self.bankName = try container.decodeIfPresent(String.self,
                                                      forKey: .bankName)
        self.isDefault = try container.decode(Bool.self,
                                              forKey: .isDefault)
    }
}
