//
//  PeakRewardsSummary.swift
//  BGE
//
//  Created by Cody Dillon on 8/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct PeakRewardsSummary: Codable {
    let devices: [SmartThermostatDevice]
    let programs: [PeakRewardsProgram]
}

struct SmartThermostatDevice: Codable, Equatable {
    let serialNumber: String
    let programNames: [String]
    let emergencyFlag: String
    let name: String
    let type: String
    let inventoryId: Int
    
    enum CodingKeys: String, CodingKey {
        case serialNumber
        case programNames = "programs"
        case emergencyFlag
        case name
        case type
        case inventoryId
    }
    
    static func ==(lhs: SmartThermostatDevice, rhs: SmartThermostatDevice) -> Bool {
        return lhs.serialNumber == rhs.serialNumber &&
            lhs.inventoryId == rhs.inventoryId
    }
    
    var isSmartThermostat: Bool {
        return !type.contains("LCR")
    }

}

struct PeakRewardsProgram: Codable {
    let name: String
    let displayName: String
    let isActive: Bool
    let status: PeakRewardsProgramStatus
    let gearName: String
    let startDate: Date?
    let stopDate: Date?
}

enum PeakRewardsProgramStatus: String, Codable {
    case active = "Active"
    case inactive = "Inactive"
}

struct PeakRewardsOverride: Decodable, Equatable {
    let serialNumber: String
    let status: OverrideStatus?
    let start: Date?
    let stop: Date?
    
     enum CodingKeys: String, CodingKey {
        case device
        case serialNumber
        case status
        case start
        case stop
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        serialNumber = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .device).decode(String.self, forKey: .serialNumber)
        status = try container.decode(OverrideStatus.self, forKey: .status)
        start = try container.decode(Date.self, forKey: .start)
        stop = try container.decode(Date.self, forKey: .stop)
    }
    
    static func ==(lhs: PeakRewardsOverride, rhs: PeakRewardsOverride) -> Bool {
        return lhs.serialNumber == rhs.serialNumber &&
            lhs.status == rhs.status &&
            lhs.start == rhs.start &&
            lhs.stop == rhs.stop
    }
    
}

enum OverrideStatus: String, Codable {
    case scheduled = "Scheduled"
    case active = "Active"
}

public struct SmartThermostatDeviceSettings: Codable {
    let temp: Temperature
    let mode: SmartThermostatMode
    let fan: SmartThermostatFan
    let hold: Bool
    
    enum CodingKeys: String, CodingKey {
        case temp
        case mode
        case fan
        case hold
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        temp = try container.decodeIfPresent(Temperature.self, forKey: .temp) ?? Temperature(value: 70.0, scale: .fahrenheit)
        mode = try container.decodeIfPresent(SmartThermostatMode.self, forKey: .mode) ?? .off
        fan = try container.decodeIfPresent(SmartThermostatFan.self, forKey: .fan) ?? .auto
        hold = try container.decodeIfPresent(Bool.self, forKey: .hold) ?? false
    }
    
    init(temp: Temperature = Temperature(value: 70.0, scale: .fahrenheit),
         mode: SmartThermostatMode = .off,
         fan: SmartThermostatFan = .auto,
         hold: Bool = false) {
        self.temp = temp
        self.mode = mode
        self.fan = fan
        self.hold = hold
    }
}

enum SmartThermostatFan: String, Codable {
    case auto = "AUTO"
    case circulate = "CIRCULATE"
    case on = "ON"
    
    var displayString: String {
        switch self {
        case .auto:
            return NSLocalizedString("Auto", comment: "")
        case .circulate:
            return NSLocalizedString("Circulate", comment: "")
        case .on:
            return NSLocalizedString("On", comment: "")
        }
    }
    
    static var allValues: [SmartThermostatFan] {
        return [.auto, .circulate, .on]
    }
}

enum SmartThermostatMode: String, Codable {
    case cool = "COOL"
    case heat = "HEAT"
    case off = "OFF"
    
    var displayString: String {
        switch self {
        case .cool:
            return NSLocalizedString("Cool", comment: "")
        case .heat:
            return NSLocalizedString("Heat", comment: "")
        case .off:
            return NSLocalizedString("Off", comment: "")
        }
    }
    
    static var allValues: [SmartThermostatMode] {
        return [.cool, .heat, .off]
    }

}

struct SmartThermostatDeviceSchedule: Codable {
    let wakeInfo: SmartThermostatPeriodInfo
    let leaveInfo: SmartThermostatPeriodInfo
    let returnInfo: SmartThermostatPeriodInfo
    let sleepInfo: SmartThermostatPeriodInfo
    
    init(wakeInfo: SmartThermostatPeriodInfo,
         leaveInfo: SmartThermostatPeriodInfo,
         returnInfo: SmartThermostatPeriodInfo,
         sleepInfo: SmartThermostatPeriodInfo) {
        self.wakeInfo = wakeInfo
        self.leaveInfo = leaveInfo
        self.returnInfo = returnInfo
        self.sleepInfo = sleepInfo
    }
    
    func info(for period: SmartThermostatPeriod) -> SmartThermostatPeriodInfo {
        switch period {
        case .wake:
            return wakeInfo
        case .leave:
            return leaveInfo
        case .return:
            return returnInfo
        case .sleep:
            return sleepInfo
        }
    }
    
    func newSchedule(forPeriod period: SmartThermostatPeriod, info: SmartThermostatPeriodInfo) -> SmartThermostatDeviceSchedule {
        switch period {
        case .wake:
            return SmartThermostatDeviceSchedule(wakeInfo: info, leaveInfo: leaveInfo, returnInfo: returnInfo, sleepInfo: sleepInfo)
        case .leave:
            return SmartThermostatDeviceSchedule(wakeInfo: wakeInfo, leaveInfo: info, returnInfo: returnInfo, sleepInfo: sleepInfo)
        case .return:
            return SmartThermostatDeviceSchedule(wakeInfo: wakeInfo, leaveInfo: leaveInfo, returnInfo: info, sleepInfo: sleepInfo)
        case .sleep:
            return SmartThermostatDeviceSchedule(wakeInfo: wakeInfo, leaveInfo: leaveInfo, returnInfo: returnInfo, sleepInfo: info)
        }
    }
}

enum SmartThermostatPeriod: String, Codable {
    case wake = "wake"
    case leave = "leave"
    case `return` = "return"
    case sleep = "sleep"
    
    var displayString: String {
        switch self {
        case .wake: return NSLocalizedString("Wake", comment: "")
        case .leave: return NSLocalizedString("Leave", comment: "")
        case .return: return NSLocalizedString("Return", comment: "")
        case .sleep: return NSLocalizedString("Sleep", comment: "")
        }
    }
}

struct SmartThermostatPeriodInfo: Codable {
    let coolTemp: Temperature
    let heatTemp: Temperature
    let startTime: Date
    
    var startTimeDisplayString: String {
        return DateFormatter.hmmaFormatter.string(from: startTime)
    }
    
    init(startTime: Date,
         coolTemp: Temperature,
         heatTemp: Temperature) {
        self.startTime = startTime
        self.coolTemp = coolTemp
        self.heatTemp = heatTemp
    }
}

struct Temperature: Codable, Equatable {
    
    private let fahrenheitValue: Double
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let tempStr = try container.decode(String.self)
        self.init(value: Double(tempStr)!, scale: .fahrenheit)
    }
    
    init(value: Double, scale: TemperatureScale) {
        switch scale {
        case .fahrenheit:
            fahrenheitValue = value
        case .celsius:
            fahrenheitValue = (value * 9.0 / 5.0) + 32.0
        }
    }
    
    init(value: Float, scale: TemperatureScale) {
        self.init(value: Double(value), scale: scale)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(fahrenheit)")
    }
    
    var fahrenheit: Int {
        return Int(round(fahrenheitValue))
    }
    
    var celsius: Int {
        return Int(round((fahrenheitValue - 32.0) * 5.0 / 9.0))
    }
    
    func value(forScale scale: TemperatureScale) -> Int {
        switch scale {
        case .fahrenheit:
            return fahrenheit
        case .celsius:
            return celsius
        }
    }
    
    static func ==(lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.fahrenheitValue == rhs.fahrenheitValue
    }
}

enum TemperatureScale: Int, Codable {
    case fahrenheit, celsius
    
    var displayString: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}
