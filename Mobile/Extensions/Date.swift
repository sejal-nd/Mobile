//
//  Date.swift
//  Mobile
//
//  Created by Sam Francis on 5/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    @nonobjc var mmDdYyyyString: String {
        return DateFormatter.mmDdYyyyFormatter.string(from: self)
    }
    
    @nonobjc var apiFormatString: String {
        return DateFormatter.apiFormatter.string(from: self)
    }
}

extension DateFormatter {
    @nonobjc static let mmDdYyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let apiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
}

// gsh - added extension to convert a Date into a String
extension String {
    @nonobjc var mmDdYyyyDate: Date {
        return DateFormatter.mmDdYyyyFormatter.date(from: self)!
    }
    
    @nonobjc var apiFormatDate: Date {
        return DateFormatter.apiFormatter.date(from: self)!
    }

}
