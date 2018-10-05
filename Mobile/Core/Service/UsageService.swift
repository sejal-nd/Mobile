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
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison>
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult>
    
    /// Fetches your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile>
    
    /// Updates your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void>
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]>


/// Fetches specific tip
///
/// - Parameters:
///   - accountNumber: the account to fetch data for
///   - premiseNumber: the premise to fetch data for
///   - tipName : the tip we are looking for
///   - completion: the block to execute upon completion, the ServiceResult
///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchEnergyTipByName(accountNumber: String, premiseNumber:String,tipName:String) -> Observable<EnergyTip>
}
