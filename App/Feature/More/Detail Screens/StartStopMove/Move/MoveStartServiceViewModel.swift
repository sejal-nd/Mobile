//
//  MoveStartServiceViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class MoveStartServiceViewModel {
    
    var moveServiceFlow: MoveServiceFlowData

    init( moveServiceFlowData: MoveServiceFlowData) {
        self.moveServiceFlow = moveServiceFlowData
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        if !moveServiceFlow.currentAccountDetail.isAMIAccount {
            let firstDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 0, to: Date.now)!)
            let secondDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date.now)!)
            let thirdDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 2, to: Date.now)!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return moveServiceFlow.workDays.contains { $0.value == calendarDate}
    }
}

