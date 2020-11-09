//
//  PeakRewardsServiceNew.swift
//  BGE
//
//  Created by Cody Dillon on 8/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct PeakRewardsService {
    static func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String, completion: @escaping (Result<PeakRewardsSummary, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .peakRewardsSummary(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String, completion: @escaping (Result<[PeakRewardsOverride], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .peakRewardsOverrides(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          deviceSerialNumber: String,
                          date: Date,
                          completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .scheduleOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, request: DateRequest(date: date)), completion: completion)
    }
    
    static func deleteOverride(accountNumber: String,
                        premiseNumber: String,
                        deviceSerialNumber: String,
                        completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .deleteOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber), completion: completion)
    }
    
    static func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             deviceSerialNumber: String,
                             completion: @escaping (Result<SmartThermostatDeviceSettings, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .deviceSettings(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber), completion: completion)
    }
    
    static func updateDeviceSettings(accountNumber: String,
                              premiseNumber: String,
                              deviceSerialNumber: String,
                              settings: SmartThermostatDeviceSettings,
                              completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateDeviceSettings(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, request: settings), completion: completion)
    }
    
    static func fetchSmartThermostatSchedule(accountNumber: String,
                                      premiseNumber: String,
                                      deviceSerialNumber: String,
                                      completion: @escaping (Result<SmartThermostatDeviceSchedule, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .thermostatSchedule(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber), completion: completion)
    }
    
    static func updateSmartThermostatSchedule(accountNumber: String,
                                       premiseNumber: String,
                                       deviceSerialNumber: String,
                                       schedule: SmartThermostatDeviceSchedule, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateThermostatSchedule(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, request: schedule), completion: completion)
    }
}
