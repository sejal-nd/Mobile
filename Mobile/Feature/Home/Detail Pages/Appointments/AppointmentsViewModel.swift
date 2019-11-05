//
//  AppointmentsViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AppointmentsViewModel {
    
    let pollInterval = 30.0
    
    let appointments: Observable<[Appointment]>
    
    required init(premiseNumber: String,
                  initialAppointments: [Appointment],
                  appointmentService: AppointmentService) {
        
        let accountService = ServiceFactory.createAccountService()
        
        // Poll for appointments
        appointments = Observable<Int>
            .interval(pollInterval, scheduler: MainScheduler.instance)
            .startWith(-1)
            .mapTo(())
            .toAsyncRequest {
                accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        }
        .elements()
        .flatMap({ accountDetail -> Observable<[Appointment]> in
            return appointmentService
                .fetchAppointments(accountNumber: accountDetail.accountNumber,
                                   premiseNumber: accountDetail.premiseNumber!)
        })
            .startWith(initialAppointments)
            .distinctUntilChanged()
            .share()
        
        // Poll for appointments
//        appointments = Observable<Int>
//            .interval(pollInterval, scheduler: MainScheduler.instance)
//            .mapTo(())
//            .toAsyncRequest {
//                appointmentService
//                    .fetchAppointments(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
//                                       premiseNumber: premiseNumber)
//            }
//            .elements()
//            // Start with passed in value
//            .startWith(initialAppointments)
//            .distinctUntilChanged()
//            .share()
    }
}
