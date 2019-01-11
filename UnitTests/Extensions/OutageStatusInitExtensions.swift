//
//  OutageStatusInitExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 8/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension MeterPingInfo {
    init(preCheckSuccess: Bool = false,
         pingResult: Bool = false,
         voltageResult: Bool = false,
         voltageReads: String = "improper") {
        
        assert(Environment.shared.environmentName == .aut, "init only available for tests")
        
        var map = [String: Any]()
        map["preCheckSuccess"] = preCheckSuccess
        map["pingResult"] = pingResult
        map["voltageResult"] = voltageResult
        map["voltageReads"] = voltageReads
        
        self = MeterPingInfo.from(map as NSDictionary)!
    }
}
