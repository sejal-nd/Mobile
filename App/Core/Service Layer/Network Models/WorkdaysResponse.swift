//
//  WorkdaysResponse.swift
//  Mobile
//
//  Created by RAMAITHANI on 12/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
public struct WorkdaysResponse: Decodable {
    
    let list: [WorkDay]
    
    struct WorkDay: Decodable {
        let key: Int
        let value: String

        enum CodingKeys: String, CodingKey {
            case key, value
            
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case list = "WorkDayList"
    }
}

extension WorkdaysResponse {
    
    static func getValidWorkdays(workdays: [WorkdaysResponse.WorkDay], isAMIAccount: Bool, isRCDCapable: Bool)-> [WorkdaysResponse.WorkDay] {
        
        if (isAMIAccount && isRCDCapable && checkPermissibleTime()) {
            return workdays
        } else if (isAMIAccount && isRCDCapable && !checkPermissibleTime()) {
            return updateWorkdays(workdays: workdays, skipDays: 1)
        } else {
            return updateWorkdays(workdays: workdays, skipDays: 3)
        }
    }

    private static func updateWorkdays(workdays: [WorkdaysResponse.WorkDay], skipDays: Int)-> [WorkdaysResponse.WorkDay] {
        
        var updatedWorkdays = workdays
        for _ in 0...(skipDays - 1) {
            updatedWorkdays.removeFirst()
        }
        return updatedWorkdays
    }

    private static func checkPermissibleTime()-> Bool {
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour < 18
    }
}

