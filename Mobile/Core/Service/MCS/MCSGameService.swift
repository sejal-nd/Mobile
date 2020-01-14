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
        return MCSApi.shared.get(pathPrefix: .auth, path: "game/\(accountNumber)")
            .map { json in
                guard let dict = json as? NSDictionary, let gameUser = GameUser.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                FirebaseUtility.setUserProperty(.gamificationGroup, value: gameUser.pilotGroup)
                FirebaseUtility.setUserProperty(.gamificationIsOptedOut, value: gameUser.optedOut ? "true" : "false")
                FirebaseUtility.setUserProperty(.gamificationIsOnboarded, value: gameUser.onboardingComplete ? "true" : "false")
                FirebaseUtility.setUserProperty(.gamificationIsClusterTwo, value: gameUser.isClusterTwo ? "true" : "false")
                
                GiftInventory.shared.auditUserDefaults(userPoints: gameUser.points)
                
                if let streakDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameStreakDateTracker) as? Date {
                    if Calendar.current.isDateInYesterday(streakDate) {
                        let streakCount = UserDefaults.standard.integer(forKey: UserDefaultKeys.gameStreakCount)
                        UserDefaults.standard.set(streakCount + 1, forKey: UserDefaultKeys.gameStreakCount)
                        UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.gameStreakDateTracker)
                    } else if abs(streakDate.interval(ofComponent: .day, fromDate: Date.now, usingCalendar: Calendar.current)) >= 2 {
                        UserDefaults.standard.set(1, forKey: UserDefaultKeys.gameStreakCount)
                    }
                }
                UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.gameStreakDateTracker)
                
                _ = self.updateGameUser(accountNumber: accountNumber, keyValues: ["lastLogin": Date.now.apiFormatString])
                    .subscribe()
                
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
                if gameUser.optedOut {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["game_weekly_reminder"])
                }
                return gameUser
            }
    }
    
    func updateGameUserGiftSelections(accountNumber: String) -> Observable<Void> {
        return self.updateGameUser(accountNumber: accountNumber, keyValues: [
            "selectedBackground": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground) ?? "none",
            "selectedHat": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat) ?? "none",
            "selectedAccessory": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory) ?? "none"
        ]).mapTo(())
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

