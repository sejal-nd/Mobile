//
//  MockAppointmentService.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockAppointmentService: AppointmentService {
    
    static var isFirstFetch = true
    
    func fetchAppointments(accountNumber: String, premiseNumber: String) -> Observable<[Appointment]> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        
        let noon = Calendar.opCo.date(byAdding: DateComponents(hour: 12),
                                      to: Calendar.opCo.startOfDay(for: Date()))!
        let one = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: noon)!
        
        let appointments: [Appointment]
        switch loggedInUsername {
        case "apptToday":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0")]
        case "apptTomorrow":
            let noonTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: noon)!
            let oneTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            
            appointments = [Appointment(id: "0", startDate: noonTomorrow, stopDate: oneTomorrow, status: .scheduled, caseNumber: "0")]
        case "apptScheduled":
            let noonLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: noon)!
            let oneLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: one)!
            
            appointments = [Appointment(id: "0", startDate: noonLaterDate, stopDate: oneLaterDate, status: .scheduled, caseNumber: "0")]
        case "apptEnRoute":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .enRoute, caseNumber: "0")]
        case "apptInProgress":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .inProgress, caseNumber: "0")]
        case "apptComplete":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .complete, caseNumber: "0")]
        case "apptCanceled":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .canceled, caseNumber: "0")]
        case "apptMultiple":
            appointments = [
                Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "01234"),
                Appointment(id: "1", startDate: noon, stopDate: one, status: .enRoute, caseNumber: "43210"),
                Appointment(id: "2", startDate: noon, stopDate: one, status: .inProgress, caseNumber: "56789"),
                Appointment(id: "3", startDate: noon, stopDate: one, status: .complete, caseNumber: "98765"),
                Appointment(id: "4", startDate: noon, stopDate: one, status: .canceled, caseNumber: "02468")
            ]
            
        // Changing response during polling
        case "apptInProgressThenComplete": // Changes the appt status after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .inProgress, caseNumber: "0")]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .complete, caseNumber: "0")]
            }
        case "apptReschedule": // Reschedules the appt after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = [Appointment(id: "0", startDate: one, stopDate: two, status: .scheduled, caseNumber: "0")]
            }
        case "apptAdd": // Starts with 2 appts, then adds 1 more after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            let three = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: two)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0"),
                                Appointment(id: "1", startDate: one, stopDate: two, status: .scheduled, caseNumber: "0"),]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0"),
                                Appointment(id: "1", startDate: one, stopDate: two, status: .scheduled, caseNumber: "0"),
                                Appointment(id: "2", startDate: two, stopDate: three, status: .scheduled, caseNumber: "0")]
            }
        case "apptRemove": // Starts with 2 appts, then removes 1 after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0"),
                                Appointment(id: "0", startDate: one, stopDate: two, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0")]
            }
        case "apptRemoveAll": // Starts with 1 appt, then removes it after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = []
            }
        case "multiApptChanges":
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [
                    Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled, caseNumber: "01234"),
                    Appointment(id: "1", startDate: noon, stopDate: one, status: .enRoute, caseNumber: "43210"),
                    Appointment(id: "2", startDate: noon, stopDate: one, status: .inProgress, caseNumber: "56789"),
                ]
            } else {
                appointments = [
                    Appointment(id: "0", startDate: noon, stopDate: one, status: .enRoute, caseNumber: "01234"),
                    Appointment(id: "1", startDate: noon, stopDate: one, status: .inProgress, caseNumber: "43210"),
                    Appointment(id: "2", startDate: noon, stopDate: one, status: .complete, caseNumber: "56789"),
                ]
            }
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
