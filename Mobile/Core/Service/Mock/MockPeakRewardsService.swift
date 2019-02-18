//
//  MockPeakRewardsService.swift
//  Mobile
//
//  Created by Samuel Francis on 2/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockPeakRewardsService: PeakRewardsService {
    
    func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary> {
        let dataFile = MockJSONManager.File.peakRewardsSummary
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]> {
        let dataFile = MockJSONManager.File.peakRewardsOverrides
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
    
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date) -> Observable<Void> {
        return .just(())
    }
    
    func deleteOverride(accountNumber: String, premiseNumber: String, device: SmartThermostatDevice) -> Observable<Void> {
        return .just(())
    }
    
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice) -> Observable<SmartThermostatDeviceSettings> {
        return .never()
    }
    
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings) -> Observable<Void> {
        return .just(())
    }
    
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String) -> Observable<SmartThermostatDeviceSchedule> {
        return .never()
    }
    
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                       accountNumber: String,
                                       premiseNumber: String,
                                       schedule: SmartThermostatDeviceSchedule) -> Observable<Void> {
        return .just(())
    }
    
}
