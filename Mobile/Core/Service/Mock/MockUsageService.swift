//
//  MockUsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MockUsageService: UsageService {
    
    init(useCache: Bool = false) { }
    
    func clearCache() { }
    
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison> {
        let dataFile = MockJSONManager.File.billComparison
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult> {
        let dataFile = MockJSONManager.File.billForecast
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.jsonArray(fromFile: dataFile, key: key)
            .map { array in
                guard let jsonArray = array as? [[String: Any]] else {
                    throw ServiceError.parsing
                }
                
                return try BillForecastResult(dictionaries: jsonArray)
        }
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile> {
        let dataFile = MockJSONManager.File.homeProfile
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void> {
        if homeProfile.squareFeet == 500 {
            return .error(ServiceError(serviceMessage: "update failed"))
        } else {
            return .just(())
        }
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]> {
        let dataFile = MockJSONManager.File.energyTips
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String) -> Observable<EnergyTip> {
        return .error(ServiceError(serviceMessage: "fetch failed"))
    }
}
