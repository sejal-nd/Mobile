//
//  MoveService+Rx.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
extension MoveService: ReactiveCompatible {}

extension Reactive where Base == MoveService {
    static func validateZip(code: String = "") -> Observable<ValidatedZipCodeResponse> {
        return Observable.create { observer -> Disposable in
            MoveService.validateZip(code: code) { observer.handle(result: $0) }

            return Disposables.create()
        }
    }
}

