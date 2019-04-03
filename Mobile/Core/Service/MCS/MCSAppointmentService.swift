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
        let threeDaysAgo = Calendar.opCo.date(byAdding: .day, value: -3, to: .now)!
        let future = Calendar.opCo.date(byAdding: .year, value: 1, to: .now)!
        let params = [
            "start_date": threeDaysAgo.yyyyMMddString,
            "end_date": future.yyyyMMddString
        ]
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/premises/\(premiseNumber)/appointments/query", params: params)
            .map { json in
                guard let array = json as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }

                return array.compactMap(Appointment.from)
                    .sorted { $0.startDate < $1.startDate }
            }
    }
}
