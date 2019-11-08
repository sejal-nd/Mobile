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
    
    var appointments: Observable<[Appointment]>!
    private (set) lazy var showLoadingState: Driver<Bool> = isLoading.asDriver()
    
    private (set) lazy var showErrorState: Driver<Bool> = Observable
        .merge(accountDetailEvents.errors(), events.errors())
        .do(onNext: { [weak self] error in
            self?.setLoading(loading: false)
        })
        .map { ($0 as? ServiceError)?.serviceCode != ServiceErrorCode.noNetworkConnection.rawValue }
        .asDriver(onErrorDriveWith: .empty())
    
    private (set) lazy var showNoNetworkState: Driver<Bool> = Observable
        .merge(accountDetailEvents.errors(), events.errors())
        .map { ($0 as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
        .asDriver(onErrorDriveWith: .empty())
    
    private (set) lazy var showEmptyState: Driver<Bool> = appointments
        .map { $0.isEmpty }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private var accountDetailEvents: Observable<Event<AccountDetail>>!
    private var events: Observable<Event<[Appointment]>>!
    private let isLoading = BehaviorRelay(value: true)
    
    private let fetchAllDataTrigger = PublishSubject<Void>()
    
    required init(initialAppointments: [Appointment],
                  appointmentService: AppointmentService,
                  accountService: AccountService) {
        
        let poll = Observable<Int>
            .interval(self.pollInterval, scheduler: MainScheduler.instance)
            .startWith(-1)
            .mapTo(())
            .do(onSubscribe: {
                self.setLoading(loading: true)
            })
        
        accountDetailEvents = fetchAllDataTrigger
            .flatMap { poll }
            .toAsyncRequest {
                accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        }
        
        events = accountDetailEvents
            .elements()
            .toAsyncRequest {
                appointmentService.fetchAppointments(accountNumber: $0.accountNumber, premiseNumber: $0.premiseNumber!)
        }
        
        // Poll for appointments
        appointments = events
            .elements()
            .startWith(initialAppointments)
            .distinctUntilChanged()
            .share()
    }
    
    func fetchAllData() {
        fetchAllDataTrigger.onNext(())
    }
    
    private func setLoading(loading: Bool) {
        self.isLoading.accept(loading)
    }
}
