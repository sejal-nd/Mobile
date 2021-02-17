//
//  Date+DueBy.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

#warning("DEAD CODE, WE PROB NEED THIS....")
//import WatchKit
//
//extension Date {
//    public func dueBy(shouldColor: Bool = true) -> NSAttributedString {
//
//        let attributes = [NSMutableAttributedString.Key.foregroundColor: UIColor.errorRed]
//
//        var due = shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")
//
//        let numberOfDays = self.interval(ofComponent: .day, fromDate: Calendar.opCo.startOfDay(for: Date()))
//
//        if numberOfDays > 6 {
//            due = NSMutableAttributedString(string: "Due by \(self.mmDdYyyyString)")
//        } else if numberOfDays == 6 {
//            due = NSMutableAttributedString(string: "Due in 6 days")
//        } else if numberOfDays == 5 {
//            due = NSMutableAttributedString(string: "Due in 5 days")
//        } else if numberOfDays == 4 {
//            due = NSMutableAttributedString(string: "Due in 4 days")
//        } else if numberOfDays == 3 {
//            due = NSMutableAttributedString(string: "Due in 3 days")
//        } else if numberOfDays == 2 {
//            due = NSMutableAttributedString(string: "Due in 2 days")
//        } else if numberOfDays == 1 {
//            due = NSMutableAttributedString(string: "Due tomorrow")
//        } else if numberOfDays == 0 {
//            due = NSMutableAttributedString(string: "Due today")
//        } else if numberOfDays < 0 {
//            due = shouldColor ? NSMutableAttributedString(string: "Due immediately", attributes: attributes) : NSMutableAttributedString(string: "Due immediately")
//        }
//
//        return due
//    }
//}
