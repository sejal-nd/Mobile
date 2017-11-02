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
    let name: Int
    let serialNumber: String
    let periods: [SmartThermostatDevicePeriod]
    
    init(map: Mapper) throws {
        name = try map.from("name")
        serialNumber = try map.from("serialNumber")
        periods = try map.from("periods")
    }
}

struct SmartThermostatDevicePeriod: Mappable {
    let coolTemp: Int
    let heatTemp: Int
    let startTime: String
    
    init(map: Mapper) throws {
        coolTemp = try map.from("coolTemp")
        heatTemp = try map.from("heatTemp")
        startTime = try map.from("startTime")
    }
}
