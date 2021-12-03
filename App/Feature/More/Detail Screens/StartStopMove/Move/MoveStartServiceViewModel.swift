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
    
    var isUnauth: Bool {
        return moveServiceFlow.unauthMoveData?.isUnauthMove ?? false
    }

    init( moveServiceFlowData: MoveServiceFlowData) {
        self.moveServiceFlow = moveServiceFlowData
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        return self.moveServiceFlow.workDays.contains { $0.value == calendarDate }
    }
}

