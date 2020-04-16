//
//  AnyEncodable.swift
//  BGE
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        // allow the encoder to intercept a particular types encoding behavior (ex. URL)
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}

extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}
