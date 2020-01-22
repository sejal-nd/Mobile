//
//  GameService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol GameService {
    
    func fetchGameUser(accountNumber: String) -> Observable<GameUser?>

    func updateGameUser(accountNumber: String, keyValues: [String: Any]) -> Observable<GameUser>
    
    func updateGameUserGiftSelections(accountNumber: String) -> Observable<Void>
    
    /// Compares how usage impacted your bill between cycles
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - gas: if true, fetches gas usage data, if false, fetches electric
    func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<[DailyUsage]>
}
