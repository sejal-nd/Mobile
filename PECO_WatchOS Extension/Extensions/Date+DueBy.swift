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

        let attributes = [NSMutableAttributedString.Key.foregroundColor: UIColor(red: 255.0 / 255.0, green: 51.0 / 255.0, blue: 0.0 / 255.0, alpha: 1)]
        
        var due = shouldIncludePrefix ? (shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")) : (shouldColor ? NSMutableAttributedString(string: "immediately", attributes: attributes) : NSMutableAttributedString(string: "immediately"))

        guard let numberOfDays = Calendar.opCo.dateComponents([.day], from: self, to: Date()).day else { return due }
        
        if numberOfDays > 5, self > Date() {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due by \(self.mmDdYyyyString)") : NSMutableAttributedString(string: "by \(self.mmDdYyyyString)")
        } else if numberOfDays == 5, self > Date() {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 5 days") : NSMutableAttributedString(string: "in 5 days")
        } else if numberOfDays == 4, self > Date() {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 4 days") : NSMutableAttributedString(string: "in 4 days")
        } else if numberOfDays == 3, self > Date() {
                due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 3 days") : NSMutableAttributedString(string: "in 3 days")
        } else if numberOfDays == 2, self > Date() {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due in 2 days") : NSMutableAttributedString(string: "in 2 days")
        } else if numberOfDays == 1, self > Date() {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due tomorrow") : NSMutableAttributedString(string: "tomorrow")
        } else if numberOfDays == 0 {
            due = shouldIncludePrefix ? NSMutableAttributedString(string: "Due today") : NSMutableAttributedString(string: "today")
        } else if numberOfDays < 0 {
            due = shouldIncludePrefix ? (shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")) : (shouldColor ? NSMutableAttributedString(string: "immediately", attributes: attributes) : NSMutableAttributedString(string: "immediately"))
        }
        
        return due
    }
    
}