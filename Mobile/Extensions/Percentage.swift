//
//  Percentage.swift
//  Mobile
//
//  Created by Junze Liu on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension NumberFormatter {
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
    
    @nonobjc var percentString: String? {
        return NumberFormatter.percentFormatter.string(from: NSNumber(value: self))
    }
}

