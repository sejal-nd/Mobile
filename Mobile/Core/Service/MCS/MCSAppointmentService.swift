//
//  MCSAppointmentService.swift
//  Mobile
//
//  Created by Samuel Francis on 10/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

class MCSAppointmentService: AppointmentService {
    func fetchAppointments(accountNumber: String, premiseNumber: String) -> Observable<[Appointment]> {
        // Implement the new PECO CAS endpoint here when it's ready.
        return .just([])
    }
}
