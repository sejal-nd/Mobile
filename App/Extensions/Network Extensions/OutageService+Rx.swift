//
//  OutageService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 12/13/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension OutageService: ReactiveCompatible {}

extension Reactive where Base == OutageService {
    
    static func fetchOutageTracker(accountNumber: String, deviceId: String, servicePointId: String) -> Observable<OutageTracker> {
        return Observable.create { observer -> Disposable in
            OutageService.fetchOutageTracker(accountNumber: accountNumber, deviceId: deviceId, servicePointId: servicePointId) { result in
                switch result {
                case .success(let tracker):
                    observer.onNext(tracker)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
