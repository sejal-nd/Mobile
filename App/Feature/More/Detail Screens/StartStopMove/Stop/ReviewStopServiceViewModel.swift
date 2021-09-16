//
//  ReviewStopServiceViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 15/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class ReviewStopServiceViewModel {
    
    
    func isValidDate(_ date: Date, workDays: [WorkdaysResponse.WorkDay], accountDetails: AccountDetail)-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        if !accountDetails.isAMIAccount {
            let firstDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 0, to: Date())!)
            let secondDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date())!)
            let thirdDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 2, to: Date())!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return workDays.contains { $0.value == calendarDate}
    }
}
