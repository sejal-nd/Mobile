//
//  BillComparisonRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BillComparisonRequest: Encodable {
    let accountNumber: String
    let premiseNumber: String
    let compareWith: String
    let fuelType: String
    
    public init(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) {
        self.accountNumber = accountNumber
        self.premiseNumber = premiseNumber
        self.compareWith = yearAgo ? "YEAR_AGO" : "PREVIOUS"
        self.fuelType = gas ? "GAS" : "ELEC"
    }
}
