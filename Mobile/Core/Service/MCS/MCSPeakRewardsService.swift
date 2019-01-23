//
//  MCSPeakRewardsService.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

class MCSPeakRewardsService: PeakRewardsService {
    
    func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let peakRewardsSummary = PeakRewardsSummary.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return peakRewardsSummary
        }
    }
    
    func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/override")
            .map { json in
                guard let array = json as? NSArray,
                    let overrides = PeakRewardsOverride.from(array) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return overrides
        }
    }
    
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/override",
        params: ["date": DateFormatter.apiFormatterGMT.string(from: date)])
            .mapTo(())
    }
    
    func deleteOverride(accountNumber: String,
                        premiseNumber: String,
                        device: SmartThermostatDevice) -> Observable<Void> {
        return MCSApi.shared.delete(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/override", params: nil)
            .mapTo(())
    }
    
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice) -> Observable<SmartThermostatDeviceSettings> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/settings")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let settings = SmartThermostatDeviceSettings.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return settings
        }
    }
    
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/settings",
        params: settings.toDictionary())
            .mapTo(())
    }
    
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String) -> Observable<SmartThermostatDeviceSchedule> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/schedule")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let smartThermostatDeviceSchedule = SmartThermostatDeviceSchedule.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return smartThermostatDeviceSchedule
        }
    }
    
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                       accountNumber: String,
                                       premiseNumber: String,
                                       schedule: SmartThermostatDeviceSchedule) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/peak/devices/\(device.serialNumber)/schedule",
            params: schedule.toDictionary())
            .mapTo(())
    }
}
