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
        
        switch accountIndex {
        case 0:
            return .just([Appointment(startTime: Date(),
                                      endTime: Date(),
                                      status: .scheduled,
                                      caseNumber: 0)])
        case 1:
            return .just([Appointment(startTime: Date(),
                                      endTime: Date(),
                                      status: .canceled,
                                      caseNumber: 1)])
        case 2:
            return .just([Appointment(startTime: Date(),
                                      endTime: Date(),
                                      status: .inProgress,
                                      caseNumber: 2),
                          Appointment(startTime: Date(),
                                      endTime: Date(),
                                      status: .canceled,
                                      caseNumber: 3)])
        default:
            return .just([])
        }
    }
}
