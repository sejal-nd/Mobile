//
//  AppointmentDetailViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AppointmentDetailViewModel {
    
    let pollInterval = 30.0
    
    let appointmentEvents: Observable<Event<[Appointment]>>
    
    required init(premiseNumber: String,
                  appointments: [Appointment],
                  appointmentService: AppointmentService) {
        
        // Poll for appointments
        appointmentEvents = Observable<Int>
            .interval(pollInterval, scheduler: MainScheduler.instance)
            .mapTo(())
            .toAsyncRequest {
                appointmentService
                    .fetchAppointments(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                       premiseNumber: premiseNumber)
            }
            // Start with passed in value
            .startWith(.next(appointments))
            .share()
    }
}
