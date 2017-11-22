//
//  ObservableExtensions.swift
//  Mobile
//
//  Created by Sam Francis on 8/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxSwiftExt

extension ObservableType {
    public func isNil<T>() -> Observable<Bool> where E == Optional<T> {
        return map { $0 == nil }
    }
}


import RxCocoa

extension SharedSequenceConvertibleType {
    public func isNil<T>() -> SharedSequence<SharingStrategy, Bool> where E == Optional<T> {
        return map { $0 == nil }
    }
}

