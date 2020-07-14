//
//  AccountDetailTestInits.swift
//  Mobile
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Mapper

protocol JSONEncodable {
    func toJSON() -> [String: Any?]
}

fileprivate extension Date {
    var apiString: String {
        return DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.string(from: self)
    }
}
