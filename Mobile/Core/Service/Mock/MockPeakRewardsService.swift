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
        if accountNumber == "programCardsDataActiveOverride" || accountNumber == "programCardsDataNoOverrides" {
            return .just(PeakRewardsSummary(
                devices: [SmartThermostatDevice(serialNumber: "123", programNames: ["Test Program"])],
                programs: [PeakRewardsProgram(name: "Test Program", displayName: "Test Program", status: .active)]
            ))
        } else if accountNumber.contains("InactiveProgram") {
            return .just(PeakRewardsSummary(
                devices: [SmartThermostatDevice(serialNumber: "123", programNames: ["Test Program"])],
                programs: [PeakRewardsProgram(name: "Test Program", displayName: "Test Program", status: .inactive)]
            ))
        } else {
            return .just(PeakRewardsSummary(devices: [SmartThermostatDevice(), SmartThermostatDevice()]))
        }
    }
    
    func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]> {
        if accountNumber.contains("NoOverrides") {
            return .just([])
        } else if accountNumber.contains("ScheduledOverride") {
            let stop = Calendar.current.date(byAdding: .hour, value: 5, to: .now)
            return .just([PeakRewardsOverride(serialNumber: "123", status: .scheduled, start: .now, stop: stop)])
        } else if accountNumber == "programCardsDataActiveOverride" || accountNumber == "programCardsDataInactiveProgram" {
            return .just([PeakRewardsOverride(serialNumber: "123", status: .active, start: .now)])
        } else {
            return .just([PeakRewardsOverride()])
        }
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
