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
        case "test-projectedCost":
            fallthrough
        case "test-projectedUsage":
            fallthrough
        case "test-projectedCostAndUsage":
            fallthrough
        case "test-projectedCostAndUsageOpower":
            fallthrough
        case "test-projectedDate":
            fallthrough
        case "test-projection-lessThan7":
            fallthrough
        case "test-projection-moreThan7":
            fallthrough
        case "test-projection-sixDaysOut":
            fallthrough
        case "test-projection-threeDaysOut":
            fallthrough
        case "test-hasForecast-referenceHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        case "test-hasForecast-forecastHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        case "test-noForecast-comparedHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220))))
        case "test-noForecast-referenceHighest":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))))
        case "forecastStartEndDate":
            fallthrough
        case "comparedReferenceStartEndDate":
            completion(.success(BillComparison(reference: UsageBillPeriod(startDate: "2018-09-02", endDate: "2018-10-01"), compared: UsageBillPeriod(startDate: "2018-08-01", endDate: "2018-08-31"))))
        case "test-avgTemp":
            completion(.success(BillComparison(reference: UsageBillPeriod(averageTemperature: 62), compared: UsageBillPeriod(averageTemperature: 89))))
        case "test-billPeriod-zeroCostDifference":
            completion(.success(BillComparison(billPeriodCostDifference: 0)))
        case "test-billPeriod-positiveCostDifference":
            completion(.success(BillComparison(billPeriodCostDifference: 10)))
        case "test-billPeriod-negativeCostDifference":
            completion(.success(BillComparison(billPeriodCostDifference: -10)))
        case "test-weather-zeroCostDifference":
            completion(.success(BillComparison(weatherCostDifference: 0)))
        case "test-weather-positiveCostDifference":
            completion(.success(BillComparison(weatherCostDifference: 10)))
        case "test-weather-negativeCostDifference":
            completion(.success(BillComparison(weatherCostDifference: -10)))
        case "test-other-zeroCostDifference":
            completion(.success(BillComparison(otherCostDifference: 0)))
        case "test-other-positiveCostDifference":
            completion(.success(BillComparison(otherCostDifference: 10)))
        case "test-other-negativeCostDifference":
            completion(.success(BillComparison(otherCostDifference: -10)))
        case "test-likelyReasons-noData":
            completion(.success(BillComparison(reference: nil, compared: nil)))
        case "test-likelyReasons-aboutSame":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 300))))
        case "test-likelyReasons-greater":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 200))))
        case "test-likelyReasons-less":
            completion(.success(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 300))))
        default:
            completion(.failure(ServiceError(serviceMessage: "account number not found")))
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<BillForecastResult>) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let threeDaysOut = Calendar.opCo.date(byAdding: .day, value: 3, to: today)!
        let sixDaysOut = Calendar.opCo.date(byAdding: .day, value: 6, to: today)!
        let twoWeeksOut = Calendar.current.date(byAdding: .weekOfMonth, value: 2, to: today)!
        
        switch accountNumber {
        case "test-hasForecast-comparedHighest":
            fallthrough
        case "test-hasForecast-referenceHighest":
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 150, meterType: "ELEC"))))
        case "test-hasForecast-forecastHighest":
            completion(.success(BillForecastResult(electric: BillForecast(projectedCost: 230, meterType: "ELEC"))))
        case "test-projectedCost":
            completion(.success(BillForecastResult(gas: BillForecast(projectedCost: 182, meterType: "GAS"),
                                                   electric: BillForecast(projectedCost: 230, meterType: "ELEC"))))
        case "test-projectedUsage":
            completion(.success(BillForecastResult(gas: BillForecast(projectedUsage: 182, meterType: "GAS"),
                                                   electric: BillForecast(projectedUsage: 230, meterType: "ELEC"))))
        case "test-projectedDate":
            completion(.success(BillForecastResult(gas: BillForecast(billingEndDate: "2019-07-03", meterType: "GAS"),
                                                   electric: BillForecast(billingEndDate: "2019-08-13", meterType: "ELEC"))))
        case "test-projectedCostAndUsage":
            fallthrough
        case "test-projectedCostAndUsageOpower":
            completion(.success(BillForecastResult(electric: BillForecast(projectedUsage: 500, projectedCost: 220, meterType: "ELEC"))))
        case "test-projection-lessThan7":
            completion(.success(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: tomorrow), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: tomorrow), meterType: "ELEC"))))
        case "test-projection-moreThan7":
            completion(.success(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut), meterType: "ELEC"))))
        case "test-projection-sixDaysOut":
            completion(.success(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut), meterType: "ELEC"))))
        case "test-projection-threeDaysOut":
            completion(.success(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut), meterType: "ELEC"))))
        case "comparedReferenceStartEndDate":
            fallthrough
        case "forecastStartEndDate":
            completion(.success(BillForecastResult(gas: BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24", meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24", meterType: "ELEC"))))
        default:
            completion(.failure(ServiceError(serviceMessage: "account number not found")))
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
