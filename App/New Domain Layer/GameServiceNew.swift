//
//  GameServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 6/10/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct GameServiceNew {
    static func fetchGameUser(accountNumber: String, completion: @escaping (Result<NewGameUser?, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .fetchGameUser(accountNumber: accountNumber)) { (result: Result<NewGameUser?, NetworkingError>) in
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
                    
                    self.updateGameUser(accountNumber: accountNumber, request: GameUserRequest(gameUser: gameUser))
                    
                    let pilotGroupLower = gameUser.pilotGroup?.lowercased()
                    if pilotGroupLower == "experimental" || pilotGroupLower == "test" || pilotGroupLower == "internal" {
                        UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
                        UserDefaults.standard.set(gameUser.onboardingComplete, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
                        UserDefaults.standard.set(gameUser.optedOut, forKey: UserDefaultKeys.gameOptedOutLocal)
                        
                        completion(.success(gameUser))
                    } else {
                        completion(.success(nil))
                    }
                }
                else {
                    completion(.success(nil))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func updateGameUser(accountNumber: String, request: GameUserRequest, completion: (((Result<NewGameUser, NetworkingError>)) -> ())? = nil) {
        NetworkingLayer.request(router: .updateGameUser(accountNumber: accountNumber, encodable: request)) { (result: Result<NewGameUser, NetworkingError>) in
            switch result {
            case .success(let user):
                completion?(.success(user))
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
}
