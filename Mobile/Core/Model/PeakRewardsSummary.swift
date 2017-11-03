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

struct SmartThermostatDevice: Mappable {
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
    let startTime: String
    
    init(map: Mapper) throws {
        let tempMapper: (Any) throws -> Temperature = { v in
            guard let valueString = v as? String else {
                throw MapperError.convertibleError(value: v, type: String.self)
            }
            guard let value = Double(valueString) else {
                throw MapperError.convertibleError(value: valueString, type: Int.self)
            }
            return Temperature(value: Int(value), scale: .fahrenheit)
        }
        
        coolTemp = try map.from("coolTemp", transformation: tempMapper)
        heatTemp = try map.from("heatTemp", transformation: tempMapper)
        
        startTime = try map.from("startTime") {
            guard let string = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: String.self)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            guard let date = dateFormatter.date(from: string) else {
                throw MapperError.convertibleError(value: string, type: Date.self)
            }
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "h:mm a"
            return dateFormatter2.string(from: date)
        }
    }
}

struct Temperature {
    private let fahrenheitValue: Double
    
    init(value: Int, scale: TemperatureScale) {
        switch scale {
        case .fahrenheit:
            fahrenheitValue = Double(value)
        case .celsius:
            fahrenheitValue = (Double(value * 9) / 5.0) + 32.0
        }
    }
    
    var fahrenheit: Int {
        return Int(round(fahrenheitValue))
    }
    
    var celsius: Int {
        return Int(round((fahrenheitValue - 32.0) * 5.0 / 9.0))
    }
    
    var value: Int {
        switch TemperatureScaleStore.shared.scale {
        case .fahrenheit:
            return fahrenheit
        case .celsius:
            return celsius
        }
    }
}










