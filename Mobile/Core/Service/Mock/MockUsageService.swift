//
//  MockUsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockUsageService: UsageService {
    
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (ServiceResult<BillComparison>) -> Void) {
        
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<[BillForecast?]>) -> Void) {
        
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<HomeProfile>) -> Void) {
        switch accountNumber {
        case "0":
            let homeProfile = HomeProfile(numberOfChildren: 4,
                                          numberOfAdults: 2,
                                          squareFeet: 3000,
                                          heatType: .electric,
                                          homeType: .singleFamily)
            completion(.Success(homeProfile))
        default:
            completion(.Failure(ServiceError(serviceMessage: "fetch failed")))
        }
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile, completion: @escaping (ServiceResult<Void>) -> Void) {
        if homeProfile.squareFeet == 500 {
            completion(.Failure(ServiceError(serviceMessage: "update failed")))
        } else {
            completion(.Success(()))
        }
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<[EnergyTip]>) -> Void) {
        switch accountNumber {
        case "8":
            let tips = Array(1...8).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            completion(ServiceResult.Success(tips))
        case "3":
            let tips = Array(1...3).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            completion(ServiceResult.Success(tips))
        default:
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "fetch failed")))
        }
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String, completion: @escaping (ServiceResult<EnergyTip>) -> Void) {
        
    }
}
