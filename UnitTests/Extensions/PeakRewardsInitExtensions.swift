//
//  PeakRewardsInitExtensions.swift
//  Mobile
//
//  Created by Samuel Francis on 2/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

private extension Date {
    var apiString: String {
        return DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: self)
    }
}

extension PeakRewardsSummary: JSONEncodable {
    
    init(devices: [SmartThermostatDevice] = [], programs: [PeakRewardsProgram] = []) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        let map: [String: Any?] = [
            "devices" : devices.map { $0.toJSON() },
            "programs" : programs.map { $0.toJSON() }
        ]
        
        self = PeakRewardsSummary.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "devices" : devices.map { $0.toJSON() },
            "programs" : programs.map { $0.toJSON() }
        ]
    }
}

extension PeakRewardsProgram: JSONEncodable {
    init(name: String = "",
         displayName: String = "",
         isActive: Bool = false,
         status: PeakRewardsProgramStatus = .inactive,
         gearName: String = "",
         startDate: Date? = nil,
         stopDate: Date? = nil) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        let map: [String: Any?] = [
            "name": name,
            "displayName": displayName,
            "isActive": isActive,
            "status": status.rawValue,
            "gearName": gearName,
            "startDate": startDate?.apiString,
            "stopDate": stopDate?.apiString
        ]
        
        self = PeakRewardsProgram.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "name": name,
            "displayName": displayName,
            "isActive": isActive,
            "status": status.rawValue,
            "gearName": gearName,
            "startDate": startDate?.apiString,
            "stopDate": stopDate?.apiString
        ]
    }
    
}

extension SmartThermostatDevice: JSONEncodable {
    
    init(serialNumber: String = "",
         programNames: [String] = [],
         emergencyFlag: String = "",
         name: String = "",
         type: String = "",
         inventoryId: Int = 0) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        let map: [String: Any?] = [
            "serialNumber": serialNumber,
            "programs": programNames,
            "emergencyFlag": emergencyFlag,
            "name": name,
            "type": type,
            "inventoryId": inventoryId
        ]
        
        self = SmartThermostatDevice.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "serialNumber": serialNumber,
            "programs": programNames,
            "emergencyFlag": emergencyFlag,
            "name": name,
            "type": type,
            "inventoryId": inventoryId
        ]
    }
}

extension PeakRewardsOverride: JSONEncodable {
    
    init(serialNumber: String = "",
         status: OverrideStatus? = nil,
         start: Date? = nil,
         stop: Date? = nil) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        let map: [String: Any?] = [
            "device" : [
                "serialNumber": serialNumber
            ],
            "status" : status?.rawValue,
            "start" : start?.apiString,
            "stop" : stop?.apiString
        ]
        
        self = PeakRewardsOverride.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "device" : [
                "serialNumber": serialNumber
            ],
            "status" : status?.rawValue,
            "start" : start?.apiString,
            "stop" : stop?.apiString
        ]
    }
    
    
}
