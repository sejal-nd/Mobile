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
        switch accountNumber {
        case "referenceEndDate":
            completion(.success(BillComparison(reference: UsageBillPeriod(endDate: "2017-08-01"))))
        case "comparedEndDate":
            completion(.success(BillComparison(compared: UsageBillPeriod(endDate: "2017-08-01"))))
        case "testReferenceMinHeight":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: -10), compared: UsageBillPeriod())))
        case "testComparedMinHeight":
            completion(.success(BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(charges: -10))))
        case "test-hasForecast-comparedHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220))))
        case "test-hasForecast-referenceHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        case "test-hasForecast-forecastHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        case "test-noForecast-comparedHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220))))
        case "test-noForecast-referenceHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        default:
            completion(.failure(ServiceError(serviceMessage: "account number not found")))
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<BillForecastResult>) -> Void) {
        switch accountNumber {
        case "test-hasForecast-comparedHighest":
            fallthrough
        case "test-hasForecast-referenceHighest":
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 150))))
        case "test-hasForecast-forecastHighest":
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 230))))
        default:
            completion(.failure(ServiceError(serviceMessage: "account number not found")))
        }
        
        
        if accountNumber == "previousBarHeightConstraint2" || accountNumber == "currentBarHeightConstraint2" {
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 150))))
        } else if accountNumber == "previousBarHeightConstraint3" || accountNumber == "previousBarHeightConstraint4" || accountNumber == "currentBarHeightConstraint3" {
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 210))))
        }
    }
    
    func fetchHomeProfile(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<HomeProfile>) -> Void) {
        switch accountNumber {
        case "0":
            let homeProfile = HomeProfile(numberOfChildren: 4,
                                          numberOfAdults: 2,
                                          squareFeet: 3000,
                                          heatType: .electric,
                                          homeType: .singleFamily)
            completion(.success(homeProfile))
        default:
            completion(.failure(ServiceError(serviceMessage: "fetch failed")))
        }
    }
    
    func updateHomeProfile(accountNumber: String, premiseNumber: String, homeProfile: HomeProfile, completion: @escaping (ServiceResult<Void>) -> Void) {
        if homeProfile.squareFeet == 500 {
            completion(.failure(ServiceError(serviceMessage: "update failed")))
        } else {
            completion(.success(()))
        }
    }
    
    func fetchEnergyTips(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<[EnergyTip]>) -> Void) {
        switch accountNumber {
        case "8":
            let tips = Array(1...8).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            completion(ServiceResult.success(tips))
        case "3":
            let tips = Array(1...3).map { EnergyTip(title: "title \($0)", body: "body \($0)") }
            completion(ServiceResult.success(tips))
        default:
            completion(ServiceResult.failure(ServiceError(serviceMessage: "fetch failed")))
        }
    }
    
    func fetchEnergyTipByName(accountNumber: String, premiseNumber: String, tipName: String, completion: @escaping (ServiceResult<EnergyTip>) -> Void) {
        
    }
}
