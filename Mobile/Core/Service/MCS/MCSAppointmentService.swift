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
        if Environment.shared.opco == .peco {
            return .just([])
        }
        
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/service/appointments/query")
            .map { json in
                guard let array = json as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return array.compactMap(Appointment.from)
                    .sorted { $0.date < $1.date }
        }
    }
}
