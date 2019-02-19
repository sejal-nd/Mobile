//
//  UnitTestExtensions.swift
//  Mobile
//
//  Created by Samuel Francis on 2/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

extension AccountDetail {
    static let `default`: AccountDetail = .fromMockJson(forKey: .default)
    
    static func fromMockJson(forKey key: MockDataKey) -> AccountDetail {
        return try! MockJSONManager.shared.mappableObject(fromFile: .accountDetails, key: key)
    }
}
