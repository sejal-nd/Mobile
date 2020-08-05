//
//  AppointmentService+RX.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/29/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension AppointmentService: ReactiveCompatible {}
extension Reactive where Base == AppointmentService {
    static func fetchAppointments(accountNumber: String, premiseNumber: String) -> Observable<[Appointment]> {
        return Observable.create { observer -> Disposable in
            AppointmentService.fetchAppointments(accountNumber: accountNumber, premiseNumber: premiseNumber) { result in
                switch result {
                case .success(let appointmentsContainer):
                    let appointments = appointmentsContainer.appointments
                    observer.onNext(appointments)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
