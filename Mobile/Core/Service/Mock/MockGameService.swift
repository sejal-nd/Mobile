//
//  MockGameService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockGameService: GameService {
    
    func fetchGameUser(accountNumber: String) -> Observable<GameUser?> {
        let testUser = GameUser(onboardingComplete: true, optedOut: false, points: 50)
        UserDefaults.standard.set(accountNumber, forKey: UserDefaultKeys.gameAccountNumber)
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.gameOnboardingCompleteLocal)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.gameOptedOutLocal)
        return Observable.just(testUser)
    }
    
    func updateGameUser(accountNumber: String, keyValues: [String: Any]) -> Observable<GameUser> {
        let testUser = GameUser(onboardingComplete: true, optedOut: false, points: 65)
        return .just(testUser)
    }
    
    func updateGameUserGiftSelections(accountNumber: String) -> Observable<Void> {
        return .just(())
    }
    
    func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<[DailyUsage]> {
        return .just([])
    }
}
