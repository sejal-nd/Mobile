//
//  DateUITestUtil.swift
//  Mobile
//
//  Created by Samuel Francis on 6/29/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

fileprivate let appName: String = {
    return Bundle.main.infoDictionary?["CFBundleName"] as! String
}()

extension Calendar {
    static let opCo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .opCo
        return calendar
    }()
    
    static let gmt: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    
    func endOfDay(for date: Date) -> Date {
        let startOfDay = Calendar.opCo.startOfDay(for: date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.opCo.date(byAdding: components, to: startOfDay)!
    }
}

extension TimeZone {
    static let opCo: TimeZone = {
        if appName.contains("BGE") || appName.contains("PECO") {
            return TimeZone(identifier: "America/New_York")!
        } else if appName.contains("ComEd") {
            return TimeZone(identifier: "America/Chicago")!
        } else {
            fatalError("Unsupported OpCo: \(appName)")
        }
    }()
    
    static let gmt = TimeZone(identifier: "GMT")!
}
