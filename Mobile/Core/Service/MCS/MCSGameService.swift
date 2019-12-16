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
//        let testUser = GameUser(onboardingComplete: true, optedOut: false, points: 15)
//        UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
//        UserDefaults.standard.set(true, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
//        UserDefaults.standard.set(false, forKey: UserDefaultKeys.gameOptedOutLocal)
//        return Observable.just(testUser)
        
        return MCSApi.shared.get(pathPrefix: .auth, path: "game/\(accountNumber)")
            .map { json in
                guard let dict = json as? NSDictionary, let gameUser = GameUser.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                GiftInventory.shared.auditUserDefaults(userPoints: gameUser.points)
                
                if gameUser.pilotGroup?.lowercased() == "experimental" {
                    UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
                    UserDefaults.standard.set(gameUser.onboardingComplete, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
                    UserDefaults.standard.set(gameUser.optedOut, forKey: UserDefaultKeys.gameOptedOutLocal)
                    return gameUser
                } else {
                    return nil
                }
            }
    }
    
    func updateGameUser(accountNumber: String, keyValues: [String: Any]) -> Observable<GameUser> {
//        let testUser = GameUser(onboardingComplete: true, optedOut: false, points: 16)
//        return Observable.just(testUser)
        
        var stringifiedDict = [String: String]()
        keyValues.forEach { (key, value) in
            if let valueStr = value as? String {
                stringifiedDict[key] = valueStr
            } else {
                stringifiedDict[key] = String(describing: value)
            }
        }
        
        return MCSApi.shared.put(pathPrefix: .auth, path: "game/\(accountNumber)", params: stringifiedDict)
            .map { json in
                guard let dict = json as? NSDictionary, let gameUser = GameUser.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                UserDefaults.standard.set(gameUser.onboardingComplete, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
                UserDefaults.standard.set(gameUser.optedOut, forKey: UserDefaultKeys.gameOptedOutLocal)
                return gameUser
            }
    }
    
    func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<[DailyUsage]> {
        let endDate = Date.now
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

