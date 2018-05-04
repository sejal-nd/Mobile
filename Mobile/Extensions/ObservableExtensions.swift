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
    
    func toAsyncRequest<T>(activityTracker: ActivityTracker? = nil,
                           requestSelector: @escaping (E) -> Observable<T>) -> Observable<Event<T>> {
        return toAsyncRequest(activityTracker: { [weak activityTracker] _ in activityTracker },
                              requestSelector: requestSelector)
    }
    
    func toAsyncRequest<T>(activityTracker: @escaping (E) -> ActivityTracker?,
                           requestSelector: @escaping (E) -> Observable<T>) -> Observable<Event<T>> {
        return flatMapLatest { element -> Observable<Event<T>> in
            var observable = requestSelector(element)
            
            if let tracker = activityTracker(element) {
                observable = observable.trackActivity(tracker)
            }
            
            return observable
                .materialize()
                .filter { !$0.isCompleted }
            }
            .share()
    }
}


import RxCocoa

extension SharedSequenceConvertibleType {
    public func isNil<T>() -> SharedSequence<SharingStrategy, Bool> where E == Optional<T> {
        return map { $0 == nil }
    }
}
