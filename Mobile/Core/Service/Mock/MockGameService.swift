//
//  MockGameService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockGameService: GameService {
    func fetchDailyUsage(accountNumber: String, premiseNumber: String, gas: Bool) -> Observable<[DailyUsage]> {
        return .just([])
    }
}
