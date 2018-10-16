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
            appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0")]
        case "apptTomorrow":
            let noonTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: noon)!
            let oneTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            
            appointments = [Appointment(jobId: "0", startTime: noonTomorrow, endTime: oneTomorrow, status: .scheduled, caseNumber: "0")]
        case "apptScheduled":
            let noonLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: noon)!
            let oneLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: one)!
            
            appointments = [Appointment(jobId: "0", startTime: noonLaterDate, endTime: oneLaterDate, status: .scheduled, caseNumber: "0")]
        case "apptEnRoute":
            appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .enRoute, caseNumber: "0")]
        case "apptInProgress":
            appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .inProgress, caseNumber: "0")]
        case "apptComplete":
            appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .complete, caseNumber: "0")]
        case "apptCanceled":
            appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .canceled, caseNumber: "0")]
        case "apptMultiple":
            appointments = [
                Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "01234"),
                Appointment(jobId: "1", startTime: noon, endTime: one, status: .enRoute, caseNumber: "43210"),
                Appointment(jobId: "2", startTime: noon, endTime: one, status: .inProgress, caseNumber: "56789"),
                Appointment(jobId: "3", startTime: noon, endTime: one, status: .complete, caseNumber: "98765"),
                Appointment(jobId: "4", startTime: noon, endTime: one, status: .canceled, caseNumber: "02468")
            ]
            
        // Changing response during polling
        case "apptInProgressThenComplete": // Changes the appt status after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .inProgress, caseNumber: "0")]
            } else {
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .complete, caseNumber: "0")]
            }
        case "apptReschedule": // Reschedules the appt after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = [Appointment(jobId: "0", startTime: one, endTime: two, status: .scheduled, caseNumber: "0")]
            }
        case "apptAdd": // Starts with 2 appts, then adds 1 more after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            let three = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: two)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0"),
                                Appointment(jobId: "1", startTime: one, endTime: two, status: .scheduled, caseNumber: "0"),]
            } else {
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0"),
                                Appointment(jobId: "1", startTime: one, endTime: two, status: .scheduled, caseNumber: "0"),
                                Appointment(jobId: "2", startTime: two, endTime: three, status: .scheduled, caseNumber: "0")]
            }
        case "apptRemove": // Starts with 2 appts, then removes 1 after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0"),
                                Appointment(jobId: "0", startTime: one, endTime: two, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0")]
            }
        case "apptRemoveAll": // Starts with 1 appt, then removes it after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(jobId: "0", startTime: noon, endTime: one, status: .scheduled, caseNumber: "0")]
            } else {
                appointments = []
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
