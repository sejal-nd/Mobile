//
//  GameService.swift
//  Mobile
//
//  Created by Cody Dillon on 6/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

#if os(iOS)
import Foundation

enum GameService {
    static func fetchGameUser(accountNumber: String, completion: @escaping (Result<GameUser?, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .fetchGameUser(accountNumber: accountNumber)) { (result: Result<GameUser?, NetworkingError>) in
            switch result {
            case .success(let data):
                
                if let gameUser = data {
                    
                    FirebaseUtility.setUserProperty(.gamificationGroup, value: gameUser.pilotGroup)
                    FirebaseUtility.setUserProperty(.gamificationCluster, value: gameUser.cluster)
                    FirebaseUtility.setUserProperty(.gamificationIsOptedOut, value: gameUser.optedOut ? "true" : "false")
                    FirebaseUtility.setUserProperty(.gamificationIsOnboarded, value: gameUser.onboardingComplete ? "true" : "false")
                    
                    GiftInventory.shared.auditUserDefaults(userPoints: gameUser.points)
                    
                    // Streak calculation
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
                    
                    var gameUserRequest = GameUserRequest(gameUser: gameUser)
                    gameUserRequest.lastLogin = Date.now.apiFormatString
                    
                    self.updateGameUser(accountNumber: accountNumber, request: gameUserRequest)
                    
                    let pilotGroupLower = gameUser.pilotGroup?.lowercased()
                    if pilotGroupLower == "experimental" || pilotGroupLower == "test" || pilotGroupLower == "internal" {
                        UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
                        UserDefaults.standard.set(gameUser.onboardingComplete, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
                        UserDefaults.standard.set(gameUser.optedOut, forKey: UserDefaultKeys.gameOptedOutLocal)
                        
                        completion(.success(gameUser))
                    } else {
                        completion(.success(nil))
                    }
                } else {
                    completion(.success(nil))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func updateGameUser(accountNumber: String, request: GameUserRequest, completion: (((Result<GameUser, NetworkingError>)) -> ())? = nil) {
        NetworkingLayer.request(router: .updateGameUser(accountNumber: accountNumber, request: request)) { (result: Result<GameUser, NetworkingError>) in
            switch result {
            case .success(let user):
                completion?(.success(user))
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    static func updateGameUserGiftSelections(accountNumber: String, completion: (((Result<GameUser, NetworkingError>)) -> ())? = nil) {
        var gameUserRequest = GameUserRequest()
        
        gameUserRequest.selectedBackground = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground) ?? "none"
        gameUserRequest.selectedHat = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat) ?? "none"
        gameUserRequest.selectedAccessory = UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory) ?? "none"
        
        updateGameUser(accountNumber: accountNumber, request: gameUserRequest, completion: completion)
    }
    
    static func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool, completion: @escaping (Result<DailyUsageData, NetworkingError>) -> ()) {
        let endDate = Date.now
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        
        let request = DailyUsageRequest(startDate: startDate, endDate: endDate, isGas: gas)
        NetworkingLayer.request(router: .fetchDailyUsage(accountNumber: accountNumber, premiseNumber: premiseNumber, request: request), completion: completion)
    }
}
#endif
