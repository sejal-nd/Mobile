//
//  MCSGameService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class MCSGameService: GameService {
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
                guard let dict = json as? [String: Any] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                return []
            }
    }
}

