//
//  PeakRewardsService.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/// The PeakRewardsService protocol defines the interface necessary
/// to deal with fetching and updating peak rewards/smart thermostat
/// settings associated with the currently logged in customer.
protocol PeakRewardsService {
    
    /// Fetch the peak rewards summary for the current customer.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary>
    
    /// Fetch the user's scheduled overrides.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]>
    
    /// Schedule an override.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to schedule the override for
    ///   - premiseNumber: the premise to schedule the override for
    ///   - device: the device to schedule the override for
    ///   - date: the date to schedule the override for
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date) -> Observable<Void>
    
    /// Delete the user's scheduled override.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to delete the override for
    ///   - premiseNumber: the premise to delete the override for
    ///   - device: the device to delete the override for
    func deleteOverride(accountNumber: String,
                        premiseNumber: String,
                        device: SmartThermostatDevice) -> Observable<Void>
    
    /// Fetch the smart thermostat device's settings.
    ///
    /// - Parameters:
    ///   - device: the device to fetch data for
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice) -> Observable<SmartThermostatDeviceSettings>
    
    /// Update the smart thermostat device's settings.
    ///
    /// - Parameters:
    ///   - device: the device to update
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - settings: the settings to update the device to
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings) -> Observable<Void>
    
    /// Fetch the smart thermostat schedule for the specified device.
    ///
    /// - Parameters:
    ///   - device: the device to fetch data for
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String) -> Observable<SmartThermostatDeviceSchedule>
    
    /// Update the thermostat schedule for the specifiied device.
    ///
    /// - Parameters:
    ///   - device: the device to update data for
    ///   - accountNumber: the account to update data for
    ///   - premiseNumber: the premise to update data for
    ///   - schedule: the premise to update data for
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String,
                                      schedule: SmartThermostatDeviceSchedule) -> Observable<Void>
    
}
