//
//  Optional+Comparable.swift
//  Mobile
//
//  Created by Samuel Francis on 1/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

extension Optional where Wrapped: Comparable {
    static func <(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): fallthrough
        case (.some(_), .none): fallthrough
        case (.none, .some(_)):
            return false
        case (.some(let lhsValue), .some(let rhsValue)):
            return lhsValue < rhsValue
        }
    }
    
    static func >(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        return rhs < lhs
    }
    
    static func <=(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.some(_), .none): fallthrough
        case (.none, .some(_)):
            return false
        case (.some(let lhsValue), .some(let rhsValue)):
            return lhsValue <= rhsValue
        }
    }
    
    static func >=(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
        return rhs <= lhs
    }
}
