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
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/accounts/\(accountNumber)/premises/\(premiseNumber)/appointments", params: nil)
            .map { json in
                guard let array = json as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                let appointments = array.compactMap(Appointment.from)
                return appointments
        }
    }
}
