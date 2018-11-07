//
//  Date+DueBy.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    
    // todo: Rename to something more descriptive
    public func dueBy() -> String {
        var due = "immediately"

        guard let numberOfDays = Calendar.opCo.dateComponents([.day], from: self, to: Date()).day else { return due }
        
        if numberOfDays > 5 {
            due = "by \(self.mmDdYyyyString)"
        } else if numberOfDays == 5 {
            due = "in 5 days"
        } else if numberOfDays == 4 {
            due = "in 4 days"
        } else if numberOfDays == 3 {
            due = "in 3 days"
        } else if numberOfDays == 2 {
            due = "in 2 days"
        } else if numberOfDays == 1 {
            due = "tomorrow"
        } else if numberOfDays == 0 {
            due = "today"
        } else if numberOfDays < 0 {
            due = "immediately"
        }
        
        return due
    }
    
}
