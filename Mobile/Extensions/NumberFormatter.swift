//
//  NumberFormatter.swift
//  Mobile
//
//  Created by Sam Francis on 5/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension NumberFormatter {
    @nonobjc static let currencyFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.numberStyle = .currency
        numberFormatter.groupingSeparator = ","
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()
    
    @nonobjc static let percentFormatter: NumberFormatter = {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.multiplier = 1.00
        percentFormatter.minimumFractionDigits = 0
        percentFormatter.maximumFractionDigits = 2
        return percentFormatter
    }()
}

extension Double {
    @nonobjc var currencyString: String {
        return NumberFormatter.currencyFormatter.string(from: NSNumber(value: self)) ?? "--"
    }
    
    @nonobjc var percentString: String? {
        return NumberFormatter.percentFormatter.string(from: NSNumber(value: self))
    }
    
    @nonobjc var twoDecimalString: String {
        return String(format: "%.2f", self)
    }
}
