//
//  AccountLookupResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountLookupResults: Decodable {
    var accountLookupResults = [AccountLookupResult]()

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.accountLookupResults = try container.decode([AccountLookupResult].self)
    }
}
