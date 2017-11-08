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
    ///     that is provided will contain an AccountPage on success, or a ServiceError on failure.
    func fetchPeakRewardsSummary(accountNumber: String,
                                 premiseNumber: String,
                                 completion: @escaping (_ result: ServiceResult<PeakRewardsSummary>) -> Void)
    
    /// Fetch a page of accounts for the current customer.
    ///
    /// - Parameters:
    ///   - device: the device to fetch data for
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain an AccountPage on success, or a ServiceError on failure.
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice,
                                      accountNumber: String,
                                      premiseNumber: String,
                                      completion: @escaping (_ result: ServiceResult<SmartThermostatDeviceSchedule>) -> Void)
    
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to PeakRewardsService
import RxSwift

extension PeakRewardsService {
    
    func fetchPeakRewardsSummary(accountNumber: String, premiseNumber: String) -> Observable<PeakRewardsSummary> {
        return Observable.create { observer in
            self.fetchPeakRewardsSummary(accountNumber: accountNumber, premiseNumber: premiseNumber) {
                switch $0 {
                case ServiceResult.Success(let peakRewardsSummary):
                    observer.onNext(peakRewardsSummary)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchSmartThermostatSchedule(forDevice device: SmartThermostatDevice, accountNumber: String, premiseNumber: String) -> Observable<SmartThermostatDeviceSchedule> {
        return Observable.create { observer in
            self.fetchSmartThermostatSchedule(forDevice: device, accountNumber: accountNumber, premiseNumber: premiseNumber) {
                switch $0 {
                case ServiceResult.Success(let smartThermostatDeviceSchedule):
                    observer.onNext(smartThermostatDeviceSchedule)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
}

