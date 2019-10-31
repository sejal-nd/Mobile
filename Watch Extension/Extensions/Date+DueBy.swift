//
//  Date+DueBy.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

extension Date {
    public func dueBy(shouldColor: Bool = false, shouldIncludePrefix: Bool = false) -> NSAttributedString {

        let attributes = [NSMutableAttributedString.Key.foregroundColor: UIColor(red: 255.0 / 255.0, green: 63.0 / 255.0, blue: 14.0 / 255.0, alpha: 1.0)]
        
        var due = shouldIncludePrefix ? (shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")) : (shouldColor ? NSMutableAttributedString(string: "immediately", attributes: attributes) : NSMutableAttributedString(string: "immediately"))
        
        let numberOfDays = self.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))

        if numberOfDays > 6 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due by \(self.mmDdYyyyString)") : NSMutableAttributedString(string: "by \(self.mmDdYyyyString)")
        } else if numberOfDays == 6 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 6 days") : NSMutableAttributedString(string: "in 6 days")
        } else if numberOfDays == 5 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 5 days") : NSMutableAttributedString(string: "in 5 days")
        } else if numberOfDays == 4 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 4 days") : NSMutableAttributedString(string: "in 4 days")
        } else if numberOfDays == 3 {
                due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 3 days") : NSMutableAttributedString(string: "in 3 days")
        } else if numberOfDays == 2 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 2 days") : NSMutableAttributedString(string: "in 2 days")
        } else if numberOfDays == 1 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due tomorrow") : NSMutableAttributedString(string: "tomorrow")
        } else if numberOfDays == 0 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due today") : NSMutableAttributedString(string: "today")
        } else if numberOfDays < 0 {
            due = shouldIncludePrefix ? (shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")) : (shouldColor ? NSMutableAttributedString(string: "immediately", attributes: attributes) : NSMutableAttributedString(string: "immediately"))
        }
        
        return due
    }
}
