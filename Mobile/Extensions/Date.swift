//
//  Date.swift
//  Mobile
//
//  Created by Sam Francis on 5/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    var mmDdYyyyString: String {
        return DateFormatter.mmDdYyyyFormatter.string(from: self)
    }
}

extension DateFormatter {
    static let mmDdYyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
}
