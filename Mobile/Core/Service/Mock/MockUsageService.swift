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
        switch accountNumber {
        case "referenceEndDate":
            return .just(BillComparison(reference: UsageBillPeriod(endDate: "2017-08-01")))
        case "comparedEndDate":
            return .just(BillComparison(compared: UsageBillPeriod(endDate: "2017-08-01")))
        case "testReferenceMinHeight":
            return .just(BillComparison(reference: UsageBillPeriod(charges: -10), compared: UsageBillPeriod()))
        case "testComparedMinHeight":
            return .just(BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(charges: -10)))
        case "test-hasForecast-comparedHighest":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220)))
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
            return .just(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200)))
        case "test-hasForecast-forecastHighest":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200)))
        case "test-noForecast-comparedHighest":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220)))
        case "test-noForecast-referenceHighest":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200)))
        case "forecastStartEndDate":
            fallthrough
        case "comparedReferenceStartEndDate":
            return .just(BillComparison(reference: UsageBillPeriod(startDate: "2018-09-02", endDate: "2018-10-01"), compared: UsageBillPeriod(startDate: "2018-08-01", endDate: "2018-08-31")))
        case "test-avgTemp":
            return .just(BillComparison(reference: UsageBillPeriod(averageTemperature: 62), compared: UsageBillPeriod(averageTemperature: 89)))
        case "test-billPeriod-zeroCostDifference":
            return .just(BillComparison(billPeriodCostDifference: 0))
        case "test-billPeriod-positiveCostDifference":
            return .just(BillComparison(billPeriodCostDifference: 10))
        case "test-billPeriod-negativeCostDifference":
            return .just(BillComparison(billPeriodCostDifference: -10))
        case "test-weather-zeroCostDifference":
            return .just(BillComparison(weatherCostDifference: 0))
        case "test-weather-positiveCostDifference":
            return .just(BillComparison(weatherCostDifference: 10))
        case "test-weather-negativeCostDifference":
            return .just(BillComparison(weatherCostDifference: -10))
        case "test-other-zeroCostDifference":
            return .just(BillComparison(otherCostDifference: 0))
        case "test-other-positiveCostDifference":
            return .just(BillComparison(otherCostDifference: 10))
        case "test-other-negativeCostDifference":
            return .just(BillComparison(otherCostDifference: -10))
        case "test-likelyReasons-noData":
            return .just(BillComparison(reference: nil, compared: nil))
        case "test-likelyReasons-aboutSame":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 300)))
        case "test-likelyReasons-greater":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 200)))
        case "test-likelyReasons-less":
            return .just(BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 300)))
        default:
            return .error(ServiceError(serviceMessage: "account number not found"))
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<BillForecastResult> {
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
            return .just(BillForecastResult(electric: BillForecast(projectedCost: 150, meterType: "ELEC")))
        case "test-hasForecast-forecastHighest":
            return .just(BillForecastResult(electric: BillForecast(projectedCost: 230, meterType: "ELEC")))
        case "test-projectedCost":
            return .just(BillForecastResult(gas: BillForecast(projectedCost: 182, meterType: "GAS"),
                                                   electric: BillForecast(projectedCost: 230, meterType: "ELEC")))
        case "test-projectedUsage":
            return .just(BillForecastResult(gas: BillForecast(projectedUsage: 182, meterType: "GAS"),
                                                   electric: BillForecast(projectedUsage: 230, meterType: "ELEC")))
        case "test-projectedDate":
            return .just(BillForecastResult(gas: BillForecast(billingEndDate: "2019-07-03", meterType: "GAS"),
                                                   electric: BillForecast(billingEndDate: "2019-08-13", meterType: "ELEC")))
        case "test-projectedCostAndUsage":
            fallthrough
        case "test-projectedCostAndUsageOpower":
            return .just(BillForecastResult(electric: BillForecast(projectedUsage: 500, projectedCost: 220, meterType: "ELEC")))
        case "test-projection-lessThan7":
            return .just(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: tomorrow), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: tomorrow), meterType: "ELEC")))
        case "test-projection-moreThan7":
            return .just(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut), meterType: "ELEC")))
        case "test-projection-sixDaysOut":
            return .just(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut), meterType: "ELEC")))
        case "test-projection-threeDaysOut":
            return .just(BillForecastResult(gas: BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut), meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut), meterType: "ELEC")))
        case "comparedReferenceStartEndDate":
            fallthrough
        case "forecastStartEndDate":
            return .just(BillForecastResult(gas: BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24", meterType: "GAS"),
                                                   electric: BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24", meterType: "ELEC")))
        default:
            return .error(ServiceError(serviceMessage: "account number not found"))
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
