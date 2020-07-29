//
//  ObservableExtensions.swift
//  Mobile
//
//  Created by Sam Francis on 8/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

extension ObservableType {
    func isNil<T>() -> Observable<Bool> where Element == Optional<T> {
        return map { $0 == nil }
    }
    
    func map<T>(_ keyPath: KeyPath<Self.Element, T>) -> Observable<T> {
        return map { $0[keyPath: keyPath] }
    }
    
    func toAsyncRequest<T>(activityTracker: ActivityTracker? = nil,
                           requestSelector: @escaping (Element) -> Observable<T>) -> Observable<Event<T>> {
        return toAsyncRequest(activityTracker: { [weak activityTracker] _ in activityTracker },
                              requestSelector: requestSelector)
    }
    
    func toAsyncRequest<T>(activityTracker: @escaping (Element) -> ActivityTracker?,
                           requestSelector: @escaping (Element) -> Observable<T>) -> Observable<Event<T>> {
        return toAsyncRequest(activityTrackers: { [activityTracker($0)].compactMap { $0 } },
                              requestSelector: requestSelector)
    }
    
    func toAsyncRequest<T>(activityTrackers: @escaping (Element) -> [ActivityTracker]?,
                           requestSelector: @escaping (Element) -> Observable<T>) -> Observable<Event<T>> {
        return flatMapLatest { element -> Observable<Event<T>> in
            var observable = requestSelector(element)
            
            activityTrackers(element)?.forEach {
                observable = observable.trackActivity($0)
            }
            
            return observable
                .materialize()
                .filter { !$0.isCompleted }
            }
            .share()
    }
}

extension ObservableType where Element: Sequence {
    func mapElements<R>(_ transform: @escaping (Self.Element.Element) throws -> R) -> Observable<Array<R>> {
        return map { try $0.map(transform) }
    }
}

import RxCocoa

extension SharedSequenceConvertibleType {
    func isNil<T>() -> SharedSequence<SharingStrategy, Bool> where Element == Optional<T> {
        return map { $0 == nil }
    }
    
    func map<T>(_ keyPath: KeyPath<Self.Element, T>) -> SharedSequence<SharingStrategy, T> {
        return map { $0[keyPath: keyPath] }
    }
}