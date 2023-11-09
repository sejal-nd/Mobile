//
//  Date+DueBy.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

extension Date {
    var dueByText: String {
        var text = "Due immediately"
        
        let numberOfDays = self.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))
        
        if numberOfDays > 6 {
            text = "Due by \(self.mmDdYyyyString)"
        } else if numberOfDays == 6 {
            text = "Due in 6 days"
        } else if numberOfDays == 5 {
            text = "Due in 5 days"
        } else if numberOfDays == 4 {
            text = "Due in 4 days"
        } else if numberOfDays == 3 {
            text = "Due in 3 days"
        } else if numberOfDays == 2 {
            text = "Due in 2 days"
        } else if numberOfDays == 1 {
            text = "Due tomorrow"
        } else if numberOfDays == 0 {
            text = "Due today"
        } else if numberOfDays < 0 {
            text = "Due immediately"
        }
        
        return text
    }
}
