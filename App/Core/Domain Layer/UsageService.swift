//
//  UsageService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct UsageService {
    
    private static var cache = UsageCache()
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, useCache: Bool = true, completion: @escaping (Result<CompareBillResult, NetworkingError>) -> ()) {
        let encodedObject = CompareBillRequest(compareWith: yearAgo ? "YEAR_AGO" : "PREVIOUS",
                                               fuelType: gas ? "GAS" : "ELEC")
        
        // Pull from cache if possible
        let cacheParams = UsageCache.ComparisonParams(accountNumber: accountNumber,
                                                             premiseNumber: premiseNumber,
                                                             yearAgo: yearAgo,
                                                             gas: gas)
        
        if useCache,
           let cachedData = cache[cacheParams] {
            completion(.success(cachedData))
        } else {
            NetworkingLayer.request(router: .compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, encodable: encodedObject)) { (result: Result<CompareBillResult, NetworkingError>) in
                switch result {
                case .success(var billComparison):
                    if useCache {
                        let params = UsageCache.ComparisonParams(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas)
                        self.cache[params] = billComparison
                    }
                    
                    // If the OPower API has no bill comparison data from a year ago, it falls back to the user's last bill (for no comprehensible reason). So we try to fix that here by cutting out bills that aren't between 11 and 13 months prior.
                    let startRangeComponents = DateComponents(calendar: .opCo, timeZone: .opCo, month: -13, day: 1)
                    let endRangeComponents = DateComponents(calendar: .opCo, timeZone: .opCo, month: -11)
                    if let referenceDate = billComparison.referenceBill?.startDate,
                        let compareDate = billComparison.comparedBill?.startDate,
                        let startRange = Calendar.opCo.date(byAdding: startRangeComponents, to: referenceDate),
                        let endRange = Calendar.opCo.date(byAdding: endRangeComponents, to: referenceDate),
                        yearAgo == true && !(startRange..<endRange ~= compareDate) {
                        
                        billComparison.comparedBill = nil
                    }
                    
                    completion(.success(billComparison))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func fetchBillForecast(accountNumber: String, premiseNumber: String, useCache: Bool = true, completion: @escaping (Result<BillForecastResult, NetworkingError>) -> ()) {
        
        let params = UsageCache.ForecastParams(accountNumber: accountNumber, premiseNumber: premiseNumber)
        if let cachedData = cache[params] {
            completion(.success(cachedData))
        } else {
            NetworkingLayer.request(router: .forecastBill(accountNumber: accountNumber, premiseNumber: premiseNumber)) { (result: Result<BillForecastResult, NetworkingError>) in
                switch result {
                case .success(let billForecast):
                    if useCache {
                        let params = UsageCache.ForecastParams(accountNumber: accountNumber, premiseNumber: premiseNumber)
                        self.cache[params] = billForecast
                    }
                    
                    completion(.success(billForecast))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func fetchHomeProfile(accountNumber: String, premiseNumber: String, completion: @escaping (Result<HomeProfile, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .homeProfileLoad(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func updateHomeProfile(accountNumber: String, premiseNumber: String, request: HomeProfileUpdateRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .homeProfileUpdate(accountNumber: accountNumber, premiseNumber: premiseNumber, encodable: request), completion: completion)
    }
    
    static func fetchEnergyTips(accountNumber: String, premiseNumber: String, completion: @escaping (Result<[EnergyTip], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .energyTips(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
    
    static func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName:String, completion: @escaping (Result<EnergyTip, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .energyTip(accountNumber: accountNumber, premiseNumber: premiseNumber, tipName: tipName), completion: completion)
    }
    
    static func fetchOpowerToken(request: B2CTokenRequest, completion: @escaping (Result<TokenResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .getOPowerAzureToken(request: request), completion: completion)
    }
    
    static func clearCache() {
        cache.clear()
    }
}

private struct UsageCache {
    private var comparisonCache = [ComparisonParams: CompareBillResult]()
    private var forecastCache = [ForecastParams: BillForecastResult]()
    
    mutating func clear() {
        comparisonCache.removeAll()
        forecastCache.removeAll()
    }
    
    subscript(comparisonParams: ComparisonParams) -> CompareBillResult? {
        get { return comparisonCache[comparisonParams] }
        set { comparisonCache[comparisonParams] = newValue }
    }
    
    subscript(forecastParams: ForecastParams) -> BillForecastResult? {
        get { return forecastCache[forecastParams] }
        set { forecastCache[forecastParams] = newValue }
    }
    
    struct ComparisonParams: Hashable {
        let accountNumber: String
        let premiseNumber: String
        let yearAgo: Bool
        let gas: Bool
    }
    
    struct ForecastParams: Hashable {
        let accountNumber: String
        let premiseNumber: String
    }
}
