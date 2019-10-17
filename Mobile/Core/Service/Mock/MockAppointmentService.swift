//
//  MockAppointmentService.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockAppointmentService: AppointmentService {
    
    var isFirstFetch = true
    
    func fetchAppointments(accountNumber: String, premiseNumber: String) -> Observable<[Appointment]> {
        var key = MockUser.current.currentAccount.dataKey(forFile: .appointments)
        
        // Changing response during polling
        switch key {
        case .apptInProgressThenComplete: // Changes the appt status after the first fetch
            if isFirstFetch {
                isFirstFetch = false
                key = .apptInProgress
            } else {
                key = .apptComplete
            }
        case .apptReschedule: // Reschedules the appt after the first fetch
            if isFirstFetch {
                isFirstFetch = false
                key = .apptScheduled
            }
        case .apptAdd: // Starts with 2 appts, then adds 1 more after the first fetch
            fallthrough
        case .apptRemove: // Starts with 2 appts, then removes 1 after the first fetch
            if isFirstFetch {
                isFirstFetch = false
                key = .apptWillChange
            }
        case .apptRemoveAll: // Starts with 1 appt, then removes it after the first fetch
            if isFirstFetch {
                isFirstFetch = false
                key = .apptScheduled
            } else {
                key = .apptNone
            }
        case .multiApptChanges:
            if isFirstFetch {
                isFirstFetch = false
                key = .apptWillMultiChange
            }
        case .apptFailure:
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        default:
            break
        }
        
        return MockJSONManager.shared.rx.mappableArray(fromFile: .appointments, key: key)
    }
    
}
