//
//  PeakRewardsService+Rx.swift
//  BGE
//
//  Created by Cody Dillon on 8/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

extension PeakRewardsService: ReactiveCompatible {}

extension Reactive where Base == PeakRewardsService {
    
    static func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary> {
        return Observable.create { observer -> Disposable in
            PeakRewardsService.fetchPeakRewardsSummary(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]> {
        return Observable.create { observer -> Disposable in
            PeakRewardsService.fetchPeakRewardsOverrides(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func scheduleOverride(accountNumber: String,
                                 premiseNumber: String,
                                 deviceSerialNumber: String,
                                 date: Date) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            PeakRewardsService.scheduleOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, date: date) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func deleteOverride(accountNumber: String,
                               premiseNumber: String,
                               deviceSerialNumber: String) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            PeakRewardsService.deleteOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func fetchDeviceSettings(accountNumber: String,
                                    premiseNumber: String,
                                    deviceSerialNumber: String) -> Observable<SmartThermostatDeviceSettings> {
        return Observable.create { observer -> Disposable in
            PeakRewardsService.fetchDeviceSettings(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func updateDeviceSettings(accountNumber: String,
                                     premiseNumber: String,
                                     deviceSerialNumber: String,
                                     settings: SmartThermostatDeviceSettings) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            PeakRewardsService.updateDeviceSettings(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, settings: settings) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func fetchSmartThermostatSchedule(accountNumber: String,
                                             premiseNumber: String,
                                             deviceSerialNumber: String) -> Observable<SmartThermostatDeviceSchedule> {
        return Observable.create { observer -> Disposable in
            PeakRewardsService.fetchSmartThermostatSchedule(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func updateSmartThermostatSchedule(accountNumber: String,
                                              premiseNumber: String,
                                              deviceSerialNumber: String,
                                              schedule: SmartThermostatDeviceSchedule) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            PeakRewardsService.updateSmartThermostatSchedule(accountNumber: accountNumber, premiseNumber: premiseNumber, deviceSerialNumber: deviceSerialNumber, schedule: schedule) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
}
