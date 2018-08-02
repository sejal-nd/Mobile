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

extension TimeZone {
    static let opCoFromAppName: TimeZone = {
        if appName.contains("BGE") || appName.contains("PECO") {
            return TimeZone(identifier: "America/New_York")!
        } else if appName.contains("ComEd") {
            return TimeZone(identifier: "America/Chicago")!
        } else {
            fatalError("Unsupported OpCo: \(appName)")
        }
    }()
}
