//
//  MockPeakRewardsService.swift
//  Mobile
//
//  Created by Samuel Francis on 2/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

class MockPeakRewardsService: PeakRewardsService {
    
    func fetchPeakRewardsSummary(accountNumber: String,
                                 premiseNumber: String,
                                 completion: @escaping (ServiceResult<PeakRewardsSummary>) -> Void) {
        completion(.Success(PeakRewardsSummary(devices: [SmartThermostatDevice(), SmartThermostatDevice()])))
    }
    
    func fetchPeakRewardsOverrides(accountNumber: String,
                                   premiseNumber: String,
                                   completion: @escaping (ServiceResult<[PeakRewardsOverride]>) -> Void) {
        completion(.Success([PeakRewardsOverride()]))
    }
    
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func deleteOverride(accountNumber: String, premiseNumber: String, device: SmartThermostatDevice, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice,
                             completion: @escaping (_ result: ServiceResult<SmartThermostatDeviceSettings>) -> Void) {
        
    }
    
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings,
                              completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
    
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String,
                                      completion: @escaping (_ result: ServiceResult<SmartThermostatDeviceSchedule>) -> Void) {
        
    }
    
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                       accountNumber: String,
                                       premiseNumber: String,
                                       schedule: SmartThermostatDeviceSchedule,
                                       completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
    
}
