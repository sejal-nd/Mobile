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
    func toVoid() -> Observable<Void> {
        return map { _ in () }
    }
    
    func debugLog(_ message: String = "") -> Observable<E> {
        return self.do(onNext: {
            dLog("\(message) -> Event \($0)")
        }, onError: {
            dLog("\(message) -> Error \($0)")
        }, onCompleted: {
            dLog("\(message) -> Completed")
        }, onSubscribe: {
            dLog("\(message) -> Subscribe")
        }, onDispose: {
            dLog("\(message) -> Disposed")
        })
    }
}

extension ObservableType where E : Optionable {
    
    public func isNil() -> Observable<Bool> {
        return map { $0.isEmpty() }
    }
    
}


import RxCocoa

extension SharedSequenceConvertibleType {
    func toVoid() -> SharedSequence<Self.SharingStrategy, Void> {
        return map { _ in () }
    }
    
    func debugLog(_ message: String = "") -> SharedSequence<SharingStrategy, E> {
        return self.do(onNext: {
            dLog("\(message) -> Event \($0)")
        }, onCompleted: {
            dLog("\(message) -> Completed")
        }, onSubscribe: {
            dLog("\(message) -> Subscribe")
        }, onDispose: {
            dLog("\(message) -> Disposed")
        })
    }
}

extension SharedSequenceConvertibleType where E : Optionable {
    
    public func isNil() -> SharedSequence<SharingStrategy, Bool> {
        return map { $0.isEmpty() }
    }
    
}

