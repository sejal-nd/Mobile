//
//  Currency.swift
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
}

extension Double {
    @nonobjc var currencyString: String {
        return NumberFormatter.currencyFormatter.string(from: NSNumber(value: self)) ?? "--"
    }
}
