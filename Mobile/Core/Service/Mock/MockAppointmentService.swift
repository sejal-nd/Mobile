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
        let accountIndex = AccountsStore.shared.accounts.index(of: AccountsStore.shared.currentAccount)
        
        let startTime = Calendar.opCo.startOfDay(for: Date()).addingTimeInterval(43_200)
        let endTime = startTime.addingTimeInterval(3600)
        switch accountIndex {
        case 0:
            return Observable<[Appointment]>
                .just([Appointment(startTime: startTime,
                                   endTime: endTime,
                                   status: .scheduled,
                                   caseNumber: "0"),
                       Appointment(startTime: startTime,
                                   endTime: endTime,
                                   status: .enRoute,
                                   caseNumber: "0"),
                       Appointment(startTime: startTime,
                                   endTime: endTime,
                                   status: .inProgress,
                                   caseNumber: "0"),
                       Appointment(startTime: startTime,
                                   endTime: endTime,
                                   status: .complete,
                                   caseNumber: "0"),
                       Appointment(startTime: startTime,
                                   endTime: endTime,
                                   status: .canceled,
                                   caseNumber: "0")])
        case 2:
            return .just([Appointment(startTime: startTime,
                                      endTime: endTime,
                                      status: .canceled,
                                      caseNumber: "1")])
        case 1:
            return .just([Appointment(startTime: startTime,
                                      endTime: endTime,
                                      status: .inProgress,
                                      caseNumber: "2"),
                          Appointment(startTime: startTime.addingTimeInterval(86_400),
                                      endTime: endTime.addingTimeInterval(86_400),
                                      status: .canceled,
                                      caseNumber: "3")])
        default:
            return .just([])
        }
    }
}
