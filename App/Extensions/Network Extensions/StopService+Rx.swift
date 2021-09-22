//
//  StopService+Rx.swift
//  Mobile
//
//  Created by RAMAITHANI on 12/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension StopService: ReactiveCompatible {}

extension Reactive where Base == StopService {
    
    static func fetchWorkdays(addressMrID: String = AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "",
                              isGasOff: Bool = false,
                              premiseOperationCenter: String = "",
                              isStart: Bool = false) -> Observable<WorkdaysResponse> {
        return Observable.create { observer -> Disposable in
            StopService.fetchWorkdays(addressMrID: addressMrID, isGasOff: isGasOff, premiseOperationCenter: premiseOperationCenter, isStart: isStart) { observer.handle(result: $0) }
            
            return Disposables.create()
        }
    }
}
    
