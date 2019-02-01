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
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].billComparisonKey
        
        do {
            let billComparison: BillComparison = try MockJSONManager.shared.mappableObject(fromFile: .billComparison, key: key)
            return .just(billComparison)
        } catch {
            return .error(error)
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult> {
        let key = MockUser.current.accounts[AccountsStore.shared.currentIndex].billForecastKey
        
        do {
            guard let json = try MockJSONManager.shared.jsonArray(fromFile: .billForecast, key: key) as? [[String: Any]] else {
                throw ServiceError.parsing
            }
            
            return .just(try BillForecastResult(dictionaries: json))
        } catch {
            return .error(error)
        }
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String) -> Observable<HomeProfile> {
        switch accountNumber {
        case "0":
            let homeProfile = HomeProfile(numberOfChildren: 4,
                                          numberOfAdults: 2,
                                          squareFeet: 3000,
                                          heatType: .electric,
                                          homeType: .singleFamily)
            return .just(homeProfile)
        default:
            return .error(ServiceError(serviceMessage: "fetch failed"))
        }
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile) -> Observable<Void> {
        if homeProfile.squareFeet == 500 {
            return .error(ServiceError(serviceMessage: "update failed"))
        } else {
            return .just(())
        }
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String) -> Observable<[EnergyTip]> {
        switch accountNumber {
        case "8":
            let tips = Array(1...8).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            return .just(tips)
        case "3":
            let tips = Array(1...3).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            return .just(tips)
        default:
            return .error(ServiceError(serviceMessage: "fetch failed"))
        }
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String) -> Observable<EnergyTip> {
        return .error(ServiceError(serviceMessage: "fetch failed"))
    }
}
