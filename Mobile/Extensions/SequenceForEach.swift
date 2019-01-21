//
//  SequenceForEach.swift
//  Mobile
//
//  Created by Samuel Francis on 3/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension Sequence {
    
    /// This is basically a `forEach` that still returns the sequence, instead of Void.
    /// Used for side effects much like `do` in RxSwift
    func doEach(_ body: (Element) throws -> ()) rethrows -> Self {
        try forEach(body)
        return self
    }
    
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
    
    func compactMap<T>(_ keyPath: KeyPath<Element, T?>) -> [T] {
        return compactMap { $0[keyPath: keyPath] }
    }
}
