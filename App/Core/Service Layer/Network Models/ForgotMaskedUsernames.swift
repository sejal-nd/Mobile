//
//  ForgotMaskedUsernames.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ForgotMaskedUsernames: Decodable {
    var maskedUsernames = [ForgotMaskedUsername]()

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.maskedUsernames = try container.decode([ForgotMaskedUsername].self)
    }
}
