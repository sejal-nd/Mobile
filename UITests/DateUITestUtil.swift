//
//  DateUITestUtil.swift
//  Mobile
//
//  Created by Samuel Francis on 6/29/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension TimeZone {
    static let opCo: TimeZone = {

        switch appOpCo {
        case .ace, .bge, .delmarva, .peco, .pepco:
            return TimeZone(identifier: "America/New_York")!
        case .comEd:
            return TimeZone(identifier: "America/Chicago")!
        }
    }()
}

extension Calendar {
    static let opCo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .opCo
        return calendar
    }()
}
