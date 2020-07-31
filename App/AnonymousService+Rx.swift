//
//  AnonymousService+RX.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension AnonymousService: ReactiveCompatible {}
extension Reactive where Base == AnonymousService {
    static func getMaintenanceMode(shouldPostNotification: Bool = false) -> Observable<MaintenanceMode> {
        return Observable.create { observer -> Disposable in
            AnonymousService.maintenanceMode(shouldPostNotification: shouldPostNotification) { result in
                switch result {
                case .success(let maintenanceMode):
                    observer.onNext(maintenanceMode)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
