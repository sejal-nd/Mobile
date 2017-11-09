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
    let programs: [String]
    let emergencyFlag: String
    let name: String
    let type: String
    let inventoryId: Int
    
    init(map: Mapper) throws {
        serialNumber = try map.from("serialNumber")
        programs = try map.from("programs")
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
    let status: String
    let gearName: String
//    let startDate: Date
//    let stopDate: Date?
    
    init(map: Mapper) throws {
        name = try map.from("name")
        displayName = try map.from("displayName")
        isActive = try map.from("isActive")
        status = try map.from("status")
        gearName = try map.from("gearName")
//        startDate = map.from("startDate")
//        stopDate = map.optionalFrom("stopDate")
    }
}

struct SmartThermostatDeviceSettings: Mappable {
    let name: String
    let serialNumber: String
    let fan: String
    let hold: Bool
    
    init(map: Mapper) throws {
        name = try map.from("name")
        serialNumber = try map.from("serialNumber")
        fan = try map.from("fan")
        hold = try map.from("hold")
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
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: startTime)
    }
    
    init(map: Mapper) throws {
        let tempMapper: (Any) throws -> Temperature = { v in
            guard let valueString = v as? String else {
                throw MapperError.convertibleError(value: v, type: String.self)
            }
            guard let value = Double(valueString) else {
                throw MapperError.convertibleError(value: valueString, type: Double.self)
            }
            return Temperature(value: value, scale: .fahrenheit)
        }
        
        coolTemp = try map.from("coolTemp", transformation: tempMapper)
        heatTemp = try map.from("heatTemp", transformation: tempMapper)
        
        startTime = try map.from("startTime") {
            guard let string = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: String.self)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = .opCo
            dateFormatter.dateFormat = "HH:mm"
            guard let date = dateFormatter.date(from: string) else {
                throw MapperError.convertibleError(value: string, type: Date.self)
            }
            
            return date
        }
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










