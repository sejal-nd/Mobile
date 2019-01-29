//
//  MultipleStringRanges.swift
//  Mobile
//
//  Created by Marc Shilling on 1/28/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

extension StringProtocol where Index == String.Index {
    func ranges<T: StringProtocol>(of string: T, options: String.CompareOptions = []) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var start: Index = startIndex
        
        while let range = range(of: string, options: options, range: start..<endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        
        return ranges
    }
}
