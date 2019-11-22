//
//  MCSGameService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class MCSGameService: GameService {
    
    func fetchGameUser(accountNumber: String) -> Observable<GameUser?> {
        return Observable.create { observer -> Disposable in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                let testUser = GameUser(onboardingComplete: false, optedOut: false, points: 0)
                UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
                observer.onNext(testUser)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<[DailyUsage]> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        let params: [String: Any] = [
            "start_date": startDate.yyyyMMddString,
            "end_date": endDate.yyyyMMddString,
            "fuel_type": gas ? "GAS" : "ELECTRICITY",
            "interval_type": "day"
        ]
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/usage/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let usageData = dict["usageData"] as? [String: Any],
                    let unit = usageData["unit"] as? String,
                    let streams = usageData["streams"] as? [[String: Any]],
                    let stream = streams.first,
                    let intervals = stream["intervals"] as? [[String: Any]] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                var array: [DailyUsage] = intervals.compactMap {
                    var dailyUsage = DailyUsage.from($0 as NSDictionary)
                    if unit == "KWH" {
                        dailyUsage?.unit = "kWh"
                    } else if unit == "THERM" {
                        dailyUsage?.unit = "therms"
                    } else {
                        dailyUsage?.unit = unit
                    }
                    return dailyUsage
                }
                
                // Most recent first
                array.sort { (a, b) -> Bool in
                    a.date > b.date
                }
                
                return array
            }
    }
}

