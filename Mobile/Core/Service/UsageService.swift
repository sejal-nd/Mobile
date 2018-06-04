//
//  UsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol UsageService {
    
    /// Compares how usage impacted your bill between cycles
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - yearAgo: if true, compares data to the previous year, if false, compares to the previous bill
    ///   - gas: if true, compares gas usage data, if false, compares electric
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a BillComparison object on success, or a ServiceError on failure.
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (_ result: ServiceResult<BillComparison>) -> Void)
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (_ result: ServiceResult<[BillForecast?]>) -> Void)
    
    /// Fetches your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchHomeProfile(accountNumber: String, premiseNumber: String, completion: @escaping (_ result: ServiceResult<HomeProfile>) -> Void)
    
    /// Updates your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchEnergyTips(accountNumber: String, premiseNumber: String, completion: @escaping (_ result: ServiceResult<[EnergyTip]>) -> Void)


/// Fetches specific tip
///
/// - Parameters:
///   - accountNumber: the account to fetch data for
///   - premiseNumber: the premise to fetch data for
///   - tipName : the tip we are looking for
///   - completion: the block to execute upon completion, the ServiceResult
///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchEnergyTipByName(accountNumber: String, premiseNumber:String,tipName:String,completion:
        @escaping (_ result: ServiceResult<EnergyTip>) -> Void)
}
/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to UsageService
extension UsageService {

    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison> {
        return Observable.create { observer in
            self.fetchBillComparison(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas, completion: { (result: ServiceResult<BillComparison>) in
                switch (result) {
                case ServiceResult.success(let billComparison):
                    observer.onNext(billComparison)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<[BillForecast?]> {
        return Observable.create { observer in
            self.fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber, completion: { (result: ServiceResult<[BillForecast?]>) in
                switch (result) {
                case ServiceResult.success(let billForecast):
                    observer.onNext(billForecast)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile> {
        return Observable.create { observer in
            self.fetchHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber, completion: { (result: ServiceResult<HomeProfile>) in
                switch (result) {
                case ServiceResult.success(let homeProfile):
                    observer.onNext(homeProfile)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]> {
        return Observable.create { observer in
            self.fetchEnergyTips(accountNumber: accountNumber, premiseNumber: premiseNumber, completion: { (result: ServiceResult<[EnergyTip]>) in
                switch (result) {
                case ServiceResult.success(let energyTips):
                    observer.onNext(energyTips)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String) -> Observable<EnergyTip> {
        return Observable.create { observer in
            self.fetchEnergyTipByName(accountNumber: accountNumber, premiseNumber: premiseNumber, tipName: tipName,completion: { (result: ServiceResult<EnergyTip>) in
                switch (result) {
                case ServiceResult.success(let energyTip):
                    observer.onNext(energyTip)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void> {
        return Observable.create { observer in
            self.updateHomeProfile(accountNumber: accountNumber, premiseNumber: premiseNumber, homeProfile: homeProfile) {
                switch ($0) {
                case ServiceResult.success(_):
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
