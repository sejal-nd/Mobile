//
//  PeakRewardsService.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

/// The PeakRewardsService protocol defines the interface necessary
/// to deal with fetching and updating peak rewards/smart thermostat
/// settings associated with the currently logged in customer.
protocol PeakRewardsService {
    
    /// Fetch the peak rewards summary for the current customer.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a PeakRewardsSummary on success, or a ServiceError on failure.
    func fetchPeakRewardsSummary(accountNumber: String,
                                 premiseNumber: String,
                                 completion: @escaping (_ result: ServiceResult<PeakRewardsSummary>) -> Void)
    
    /// Fetch the user's scheduled overrides.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a PeakRewardsOverride on success, or a ServiceError on failure.
    func fetchPeakRewardsOverrides(accountNumber: String,
                                   premiseNumber: String,
                                   completion: @escaping (_ result: ServiceResult<[PeakRewardsOverride]>) -> Void)
    
    /// Schedule an override.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to schedule the override for
    ///   - premiseNumber: the premise to schedule the override for
    ///   - device: the device to schedule the override for
    ///   - date: the date to schedule the override for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a PeakRewardsOverride on success, or a ServiceError on failure.
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date,
                          completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Delete the user's scheduled override.
    ///
    /// - Parameters:
    ///   - accountNumber: the account to delete the override for
    ///   - premiseNumber: the premise to delete the override for
    ///   - device: the device to delete the override for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a PeakRewardsOverride on success, or a ServiceError on failure.
    func deleteOverride(accountNumber: String,
                        premiseNumber: String,
                        device: SmartThermostatDevice,
                        completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Fetch the smart thermostat device's settings.
    ///
    /// - Parameters:
    ///   - device: the device to fetch data for
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a SmartThermostatDeviceSettings on success, or a ServiceError on failure.
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice,
                             completion: @escaping (_ result: ServiceResult<SmartThermostatDeviceSettings>) -> Void)
    
    /// Update the smart thermostat device's settings.
    ///
    /// - Parameters:
    ///   - device: the device to update
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - settings: the settings to update the device to
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a SmartThermostatDeviceSettings on success, or a ServiceError on failure.
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings,
                              completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Fetch the smart thermostat schedule for the specified device.
    ///
    /// - Parameters:
    ///   - device: the device to fetch data for
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a SmartThermostatDeviceSchedule on success, or a ServiceError on failure.
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String,
                                      completion: @escaping (_ result: ServiceResult<SmartThermostatDeviceSchedule>) -> Void)
    
    /// Update the thermostat schedule for the specifiied device.
    ///
    /// - Parameters:
    ///   - device: the device to update data for
    ///   - accountNumber: the account to update data for
    ///   - premiseNumber: the premise to update data for
    ///   - schedule: the premise to update data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain Void on success, or a ServiceError on failure.
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String,
                                      schedule: SmartThermostatDeviceSchedule,
                                      completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to PeakRewardsService
import RxSwift

extension PeakRewardsService {
    
    func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary> {
        return Observable.create { observer in
            self.fetchPeakRewardsSummary(accountNumber: accountNumber, premiseNumber: premiseNumber) {
                switch $0 {
                case ServiceResult.success(let peakRewardsSummary):
                    observer.onNext(peakRewardsSummary)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchPeakRewardsOverrides(accountNumber: String, premiseNumber: String) -> Observable<[PeakRewardsOverride]> {
        return Observable.create { observer in
            self.fetchPeakRewardsOverrides(accountNumber: accountNumber, premiseNumber: premiseNumber) {
                switch $0 {
                case ServiceResult.success(let overrides):
                    observer.onNext(overrides)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func scheduleOverride(accountNumber: String,
                          premiseNumber: String,
                          device: SmartThermostatDevice,
                          date: Date) -> Observable<Void> {
        return Observable.create { observer in
            self.scheduleOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, device: device, date: date) { result in
                switch result {
                case ServiceResult.success(()):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func deleteOverride(accountNumber: String,
                        premiseNumber: String,
                        device: SmartThermostatDevice) -> Observable<Void> {
        return Observable.create { observer in
            self.deleteOverride(accountNumber: accountNumber, premiseNumber: premiseNumber, device: device) { result in
                switch result {
                case ServiceResult.success(()):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchDeviceSettings(accountNumber: String,
                             premiseNumber: String,
                             device: SmartThermostatDevice) -> Observable<SmartThermostatDeviceSettings> {
        return Observable.create { observer in
            self.fetchDeviceSettings(accountNumber: accountNumber, premiseNumber: premiseNumber, device: device) {
                switch $0 {
                case ServiceResult.success(let settings):
                    observer.onNext(settings)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func updateDeviceSettings(forDevice device: SmartThermostatDevice,
                              accountNumber: String,
                              premiseNumber: String,
                              settings: SmartThermostatDeviceSettings) -> Observable<Void> {
        return Observable.create { observer in
            self.updateDeviceSettings(forDevice: device, accountNumber: accountNumber, premiseNumber: premiseNumber, settings: settings) { result in
                switch result {
                case ServiceResult.success(()):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice, accountNumber: String, premiseNumber: String) -> Observable<SmartThermostatDeviceSchedule> {
        return Observable.create { observer in
            self.fetchSmartThermostatSchedule(forDevice: device, accountNumber: accountNumber, premiseNumber: premiseNumber) { result in
                switch result {
                case ServiceResult.success(let smartThermostatDeviceSchedule):
                    observer.onNext(smartThermostatDeviceSchedule)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func updateSmartThermostatSchedule(forDevice device: SmartThermostatDevice, accountNumber: String, premiseNumber: String, schedule: SmartThermostatDeviceSchedule) -> Observable<Void> {
        return Observable.create { observer in
            self.updateSmartThermostatSchedule(forDevice: device, accountNumber: accountNumber, premiseNumber: premiseNumber, schedule: schedule) { result in
                switch result {
                case ServiceResult.success(()):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
}

