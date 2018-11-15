//
//  PeakRewardsSummary.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct PeakRewardsSummary: Mappable {
    let devices: [SmartThermostatDevice]
    let programs: [PeakRewardsProgram]
    
    init(map: Mapper) throws {
        devices = try map.from("devices")
        programs = try map.from("programs")
    }
}

struct SmartThermostatDevice: Mappable, Equatable {
    let serialNumber: String
    let programNames: [String]
    let emergencyFlag: String
    let name: String
    let type: String
    let inventoryId: Int
    
    init(map: Mapper) throws {
        serialNumber = try map.from("serialNumber")
        programNames = try map.from("programs")
        emergencyFlag = try map.from("emergencyFlag")
        name = try map.from("name")
        type = try map.from("type")
        inventoryId = try map.from("inventoryId")
    }
    
    static func ==(lhs: SmartThermostatDevice, rhs: SmartThermostatDevice) -> Bool {
        return lhs.serialNumber == rhs.serialNumber &&
            lhs.inventoryId == rhs.inventoryId
    }
    
    var isSmartThermostat: Bool {
        return !type.contains("LCR")
    }

}

struct PeakRewardsProgram: Mappable {
    let name: String
    let displayName: String
    let isActive: Bool
    let status: PeakRewardsProgramStatus
    let gearName: String
    let startDate: Date?
    let stopDate: Date?
    
    init(map: Mapper) throws {
        name = try map.from("name")
        displayName = try map.from("displayName")
        isActive = try map.from("isActive")
        status = try map.from("status") {
            guard let string = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: String.self)
            }
            
            guard let status = PeakRewardsProgramStatus(rawValue: string) else {
                throw MapperError.convertibleError(value: string, type: PeakRewardsProgramStatus.self)
            }
            
            return status
        }
        gearName = try map.from("gearName")

        startDate = map.optionalFrom("startDate", transformation: DateParser().extractDate)
        stopDate = map.optionalFrom("stopDate", transformation: DateParser().extractDate)
    }
}

enum PeakRewardsProgramStatus: String {
    case active = "Active"
    case inactive = "Inactive"
}

struct PeakRewardsOverride: Mappable, Equatable {
    let serialNumber: String
    let status: OverrideStatus?
    let start: Date?
    let stop: Date?
    
    init(map: Mapper) throws {
        status = map.optionalFrom("status") {
            guard let string = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: String.self)
            }
            
            guard let status = OverrideStatus(rawValue: string) else {
                throw MapperError.convertibleError(value: string, type: OverrideStatus.self)
            }
            
            return status
        }
        
        start = map.optionalFrom("start", transformation: DateParser().extractDate)
        stop = map.optionalFrom("stop", transformation: DateParser().extractDate)
        
        serialNumber = try map.from("device.serialNumber")
    }
    
    static func ==(lhs: PeakRewardsOverride, rhs: PeakRewardsOverride) -> Bool {
        return lhs.serialNumber == rhs.serialNumber &&
            lhs.status == rhs.status &&
            lhs.start == rhs.start &&
            lhs.stop == rhs.stop
    }
    
}

enum OverrideStatus: String {
    case scheduled = "Scheduled"
    case active = "Active"
}

struct SmartThermostatDeviceSettings: Mappable {
    let temp: Temperature
    let mode: SmartThermostatMode
    let fan: SmartThermostatFan
    let hold: Bool
    
    init(map: Mapper) throws {
        temp = try map.from("temp", transformation: tempMapper)
        mode = try map.from("mode")
        fan = try map.from("fan")
        hold = try map.from("hold")
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
    
    func toDictionary() -> [String: Any] {
        return ["temp": temp.fahrenheit,
                "mode": mode.rawValue,
                "fan": fan.rawValue,
                "hold": hold]
    }
}

enum SmartThermostatFan: String {
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

enum SmartThermostatMode: String {
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

struct SmartThermostatDeviceSchedule: Mappable {
    let wakeInfo: SmartThermostatPeriodInfo
    let leaveInfo: SmartThermostatPeriodInfo
    let returnInfo: SmartThermostatPeriodInfo
    let sleepInfo: SmartThermostatPeriodInfo
    
    init(map: Mapper) throws {
        wakeInfo = try map.from("wake")
        leaveInfo = try map.from("leave")
        returnInfo = try map.from("return")
        sleepInfo = try map.from("sleep")
    }
    
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
    
    func toDictionary() -> [String: Any] {
        return ["wake": wakeInfo.toDictionary(),
                "leave": leaveInfo.toDictionary(),
                "return": returnInfo.toDictionary(),
                "sleep": sleepInfo.toDictionary()]
    }
}

enum SmartThermostatPeriod: String {
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

struct SmartThermostatPeriodInfo: Mappable {
    let coolTemp: Temperature
    let heatTemp: Temperature
    let startTime: Date
    
    var startTimeDisplayString: String {
        return DateFormatter.hmmaFormatter.string(from: startTime)
    }
    
    init(map: Mapper) throws {
        coolTemp = try map.from("coolTemp", transformation: tempMapper)
        heatTemp = try map.from("heatTemp", transformation: tempMapper)
        startTime = try map.from("startTime", transformation: DateParser().extractDate)
    }
    
    init(startTime: Date,
         coolTemp: Temperature,
         heatTemp: Temperature) {
        self.startTime = startTime
        self.coolTemp = coolTemp
        self.heatTemp = heatTemp
    }
    
    func toDictionary() -> [String: Any] {
        return ["coolTemp": coolTemp.fahrenheit, "heatTemp": heatTemp.fahrenheit, "startTime": DateFormatter.HHmmFormatter.string(from: startTime)]
    }
}

struct Temperature: Equatable {
    
    private let fahrenheitValue: Double
    
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

fileprivate let tempMapper: (Any) throws -> Temperature = { v in
    guard let valueString = v as? String else {
        throw MapperError.convertibleError(value: v, type: String.self)
    }
    guard let value = Double(valueString) else {
        throw MapperError.convertibleError(value: valueString, type: Double.self)
    }
    return Temperature(value: value, scale: .fahrenheit)
}



