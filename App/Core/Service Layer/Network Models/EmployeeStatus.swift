//
//  EmployeeStatus.swift
//  Mobile
//
//  Created by RAMAITHANI on 20/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct EmployeeStatus {
    
    static let employeeStatusDictionary = ["Employed more than 3 years": "OVER 3 YRS", "Employed less than 3 years": "LESS THAN 3 YRS", "Retired": "RETIRED", "Receives assistance": "RECEIVES ASST", "Other": "UNEMPLOYED"]
        
    static let employeeStatusList = ["Employed more than 3 years", "Employed less than 3 years", "Retired", "Receives assistance", "Other"]
    
    static func getEmployeeStatus(_ key: String)-> String {
        return EmployeeStatus.employeeStatusDictionary[key] ?? ""
    }
}
