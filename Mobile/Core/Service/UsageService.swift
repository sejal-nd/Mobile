//
//  UsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol UsageService {
    
    init(useCache: Bool)
    
    /// Compares how usage impacted your bill between cycles
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - yearAgo: if true, compares data to the previous year, if false, compares to the previous bill
    ///   - gas: if true, compares gas usage data, if false, compares electric
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison>
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult>
    
    /// Fetches your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile>
    
    #if os(iOS)
    /// Updates your home profile data
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void>
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]>


    /// Fetches specific tip
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - tipName : the tip we are looking for
    func fetchEnergyTipByName(accountNumber: String, premiseNumber:String,tipName:String) -> Observable<EnergyTip>
    #endif

    
    /// Clears the local bill comparison/forecast cache
    func clearCache()
}
