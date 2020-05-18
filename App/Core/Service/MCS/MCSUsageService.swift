//
//  MCSUsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MCSUsageService: UsageService {
    let useCache: Bool
    
    required init(useCache: Bool) {
        self.useCache = useCache
    }
    
    private var cache = BillAnalysisCache()
    
    func clearCache() {
        cache.clear()
    }
    
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison> {
        let dataObservable: Observable<BillComparison>
        
        // Pull from cache if possible
        let cacheParams = BillAnalysisCache.ComparisonParams(accountNumber: accountNumber,
                                                             premiseNumber: premiseNumber,
                                                             yearAgo: yearAgo,
                                                             gas: gas)
        
        if let cachedData = cache[cacheParams] {
            dataObservable = Observable.just(cachedData)
        } else {
            let params = ["compare_with": yearAgo ? "YEAR_AGO" : "PREVIOUS",
                          "fuel_type": gas ? "GAS" : "ELEC"]
            
            dataObservable = MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/usage/compare_bills", params: params)
                .map { response in
                    guard let dict = response as? NSDictionary, let billComparison = BillComparison.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    // If the OPower API has no bill comparison data from a year ago, it falls back to the user's last bill (for no comprehensible reason). So we try to fix that here by cutting out bills that aren't between 11 and 13 months prior.
                    let startRangeComponents = DateComponents(calendar: .opCo, timeZone: .opCo, month: -13, day: 1)
                    let endRangeComponents = DateComponents(calendar: .opCo, timeZone: .opCo, month: -11)
                    if let referenceDate = billComparison.reference?.startDate,
                        let compareDate = billComparison.compared?.startDate,
                        let startRange = Calendar.opCo.date(byAdding: startRangeComponents, to: referenceDate),
                        let endRange = Calendar.opCo.date(byAdding: endRangeComponents, to: referenceDate),
                        yearAgo == true && !(startRange..<endRange ~= compareDate) {
                        let fixedComparison = BillComparison(meterUnit: billComparison.meterUnit,
                                                             currencySymbol: billComparison.currencySymbol,
                                                             temperatureUnit: billComparison.temperatureUnit,
                                                             reference: billComparison.reference,
                                                             compared: nil,
                                                             billPeriodCostDifference: billComparison.billPeriodCostDifference,
                                                             weatherCostDifference: billComparison.weatherCostDifference,
                                                             otherCostDifference: billComparison.otherCostDifference)
                        
                        return fixedComparison
                    } else {
                        return billComparison
                    }
                }
        }
        
        return dataObservable
            .do(onNext: { [weak self] in
                guard let self = self, self.useCache else { return }
                let params = BillAnalysisCache.ComparisonParams(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas)
                self.cache[params] = $0
            })
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult> {
        let dataObservable: Observable<BillForecastResult>
        
        // Pull from cache if possible
        let cacheParams = BillAnalysisCache.ForecastParams(accountNumber: accountNumber, premiseNumber: premiseNumber)
        if let cachedData = cache[cacheParams] {
            dataObservable = Observable.just(cachedData)
        } else {
            dataObservable = MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/usage/forecast_bill")
                .map { response in
                    guard let array = response as? [[String: Any]] else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    do {
                        let result = try BillForecastResult(dictionaries: array)
                        return result
                    } catch {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                }
        }
        
        return dataObservable
            .do(onNext: { [weak self] in
                guard let self = self, self.useCache else { return }
                let params = BillAnalysisCache.ForecastParams(accountNumber: accountNumber, premiseNumber: premiseNumber)
                self.cache[params] = $0
            })
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/home_profile")
            .map { response in
                guard let dict = response as? NSDictionary, let homeProfile = HomeProfile.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return homeProfile
            }
    }
    
    #if os(iOS)
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void> {
        guard homeProfile.isFilled else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        }
        
        let params: [String: Any] = [
            "heat_type": homeProfile.heatType!.apiString,
            "dwelling_type": homeProfile.homeType!.apiString,
            "square_feet": homeProfile.squareFeet!,
            "adult_count": homeProfile.numberOfAdults!,
            "child_count": homeProfile.numberOfChildren!,
        ]
        
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/home_profile", params: params)
            .mapTo(())
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/tips")
            .map { response in
                guard let array = response as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return array.compactMap(EnergyTip.from)
            }
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber:String, tipName:String) -> Observable<EnergyTip> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/tips/\(tipName)")
            .map { response in
                guard let dict = response as? NSDictionary, let tip = EnergyTip.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return tip
            }
    }
    #endif

    private struct BillAnalysisCache {
        private var comparisonCache = [ComparisonParams: BillComparison]()
        private var forecastCache = [ForecastParams: BillForecastResult]()
        
        mutating func clear() {
            comparisonCache.removeAll()
            forecastCache.removeAll()
        }
        
        subscript(comparisonParams: ComparisonParams) -> BillComparison? {
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
}
