//
//  UsageService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum UsageService {
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (Result<CompareBillResult, NetworkingError>) -> ()) {
        let encodedObject = CompareBillRequest(compareWith: yearAgo ? "YEAR_AGO" : "PREVIOUS",
                                               fuelType: gas ? "GAS" : "ELEC")
        NetworkingLayer.request(router: .compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, encodable: encodedObject), completion: completion)
    }
    
    // TODO: implement caching
    static func fetchBillForecast(accountNumber: String, premiseNumber: String, useCache: Bool = false, completion: @escaping (Result<BillForecastResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .forecastBill(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
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
    
    static func clearCache() {
        // TODO: implement caching
    }
}
