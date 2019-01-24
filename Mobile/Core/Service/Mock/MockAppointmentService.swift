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
                                      to: Calendar.opCo.startOfDay(for: .now))!
        let one = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: noon)!
        
        let appointments: [Appointment]
        switch loggedInUsername {
        case "apptToday":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled)]
        case "apptTomorrow":
            let noonTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: noon)!
            let oneTomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: one)!
            
            appointments = [Appointment(id: "0", startDate: noonTomorrow, stopDate: oneTomorrow, status: .scheduled)]
        case "apptScheduled":
            let noonLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: noon)!
            let oneLaterDate = Calendar.opCo.date(byAdding: DateComponents(day: 5), to: one)!
            
            appointments = [Appointment(id: "0", startDate: noonLaterDate, stopDate: oneLaterDate, status: .scheduled)]
        case "apptEnRoute":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .enRoute)]
        case "apptInProgress":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .inProgress)]
        case "apptComplete":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .complete)]
        case "apptCanceled":
            appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .canceled)]
        case "apptMultiple":
            appointments = [
                Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled),
                Appointment(id: "1", startDate: noon, stopDate: one, status: .enRoute),
                Appointment(id: "2", startDate: noon, stopDate: one, status: .inProgress),
                Appointment(id: "3", startDate: noon, stopDate: one, status: .complete),
                Appointment(id: "4", startDate: noon, stopDate: one, status: .canceled)
            ]
            
        // Changing response during polling
        case "apptInProgressThenComplete": // Changes the appt status after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .inProgress)]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .complete)]
            }
        case "apptReschedule": // Reschedules the appt after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled)]
            } else {
                appointments = [Appointment(id: "0", startDate: one, stopDate: two, status: .scheduled)]
            }
        case "apptAdd": // Starts with 2 appts, then adds 1 more after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            let three = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: two)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled),
                                Appointment(id: "1", startDate: one, stopDate: two, status: .scheduled),]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled),
                                Appointment(id: "1", startDate: one, stopDate: two, status: .scheduled),
                                Appointment(id: "2", startDate: two, stopDate: three, status: .scheduled)]
            }
        case "apptRemove": // Starts with 2 appts, then removes 1 after the first fetch
            let two = Calendar.opCo.date(byAdding: DateComponents(hour: 1), to: one)!
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled),
                                Appointment(id: "0", startDate: one, stopDate: two, status: .scheduled)]
            } else {
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled)]
            }
        case "apptRemoveAll": // Starts with 1 appt, then removes it after the first fetch
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled)]
            } else {
                appointments = []
            }
        case "multiApptChanges":
            if MockAppointmentService.isFirstFetch {
                MockAppointmentService.isFirstFetch = false
                appointments = [
                    Appointment(id: "0", startDate: noon, stopDate: one, status: .scheduled),
                    Appointment(id: "1", startDate: noon, stopDate: one, status: .enRoute),
                    Appointment(id: "2", startDate: noon, stopDate: one, status: .inProgress),
                ]
            } else {
                appointments = [
                    Appointment(id: "0", startDate: noon, stopDate: one, status: .enRoute),
                    Appointment(id: "1", startDate: noon, stopDate: one, status: .inProgress),
                    Appointment(id: "2", startDate: noon, stopDate: one, status: .complete),
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
