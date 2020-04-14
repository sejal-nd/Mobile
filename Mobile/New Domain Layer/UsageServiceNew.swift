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
        let httpBodyParameters = ["compare_with": yearAgo ? "YEAR_AGO" : "PREVIOUS",
        "fuel_type": gas ? "GAS" : "ELEC"]
        
        
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: httpBodyParameters)
            print("REQ SCHEDULE")
            
            ServiceLayer.request(router: .compareBill(accountNumber: accountNumber, premiseNumber: premiseNumber, httpBody: httpBody)) { (result: Result<NewCompareBillResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 5 SUCCESS: \(data.temperatureUnit) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 5 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
            //                                                                            switch result {
            //                case .success(let data):
            //
            //                    // fetch accounts todo
            //
            //                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
            //                case .failure(let error):
            //                    print("NetworkTest POST 2 FAIL: \(error)")
            //                    //                completion(.failure(error))
            //                }
            //            }
        } catch let error {
            print("Error encoding values: \(error)")
            print("REQ ERROR")
        }
    }
    
}
