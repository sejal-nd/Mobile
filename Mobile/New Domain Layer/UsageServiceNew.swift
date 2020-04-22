//
//  UsageServiceNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct UsageServiceNew {
    
    static func compareBill(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) {
//        let httpBodyParameters = ["compare_with": yearAgo ? "YEAR_AGO" : "PREVIOUS",
//        "fuel_type": gas ? "GAS" : "ELEC"]

        let encodedObject = CompareBillRequest(compareWith: yearAgo ? "YEAR_AGO" : "PREVIOUS",
                                               fuelType: gas ? "GAS" : "ELEC")
        
            ServiceLayer.request(router: .compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, encodable: encodedObject)) { (result: Result<NewCompareBillResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 5 SUCCESS: \(data.temperatureUnit) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 5 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
    }
    
}
