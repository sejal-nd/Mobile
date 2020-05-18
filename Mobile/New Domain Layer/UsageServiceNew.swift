//
//  UsageServiceNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct UsageServiceNew {
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (Result<NewCompareBillResult, NetworkingError>) -> ()) {
        let encodedObject = CompareBillRequest(compareWith: yearAgo ? "YEAR_AGO" : "PREVIOUS",
                                               fuelType: gas ? "GAS" : "ELEC")
        NetworkingLayer.request(router: .compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, encodable: encodedObject), completion: completion)
    }
}
