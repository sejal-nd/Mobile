//
//  MockAppointmentService.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockAppointmentService: AppointmentService {
    func fetchAppointments(accountNumber: String, premiseNumber: String) -> Observable<[Appointment]> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        
        let noon = Calendar.opCo.date(byAdding: DateComponents(hour: 12),
                                      to: Calendar.opCo.startOfDay(for: Date()))!
        let one = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: noon)!
        
        let appointments: [Appointment]
        switch loggedInUsername {
        case "apptToday":
            appointments = [Appointment(startTime: noon, endTime: one, status: .scheduled, caseNumber: "0")]
        case "apptTomorrow":
            let noonTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: noon)!
            let oneTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            
            appointments = [Appointment(startTime: noonTomorrow, endTime: oneTomorrow, status: .scheduled, caseNumber: "0")]
        case "apptScheduled":
            let noonLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: noon)!
            let oneLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: one)!
            
            appointments = [Appointment(startTime: noonLaterDate, endTime: oneLaterDate, status: .scheduled, caseNumber: "0")]
        case "apptEnRoute":
            appointments = [Appointment(startTime: noon, endTime: one, status: .enRoute, caseNumber: "0")]
        case "apptInProgress":
            appointments = [Appointment(startTime: noon, endTime: one, status: .inProgress, caseNumber: "0")]
        case "apptComplete":
            appointments = [Appointment(startTime: noon, endTime: one, status: .complete, caseNumber: "0")]
        case "apptCanceled":
            appointments = [Appointment(startTime: noon, endTime: one, status: .canceled, caseNumber: "0")]
        case "apptMultiple":
            appointments = [
                Appointment(startTime: noon, endTime: one, status: .scheduled, caseNumber: "01234"),
                Appointment(startTime: noon, endTime: one, status: .enRoute, caseNumber: "43210"),
                Appointment(startTime: noon, endTime: one, status: .inProgress, caseNumber: "56789"),
                Appointment(startTime: noon, endTime: one, status: .complete, caseNumber: "98765"),
                Appointment(startTime: noon, endTime: one, status: .canceled, caseNumber: "02468")
            ]
        case "apptFailure":
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        case "apptNone":
            fallthrough
        default:
            appointments = []
        }
        
        return .just(appointments)
    }
}
