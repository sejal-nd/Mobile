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
    let pollInterval = 30
    
    var contactNumber: String {
        switch Configuration.shared.opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-494-4000"
        case .comEd: return "1-800-334-7661"
        default: return ""
        }
    }
    
    var appointments: Observable<[Appointment]>!
    private (set) lazy var showLoadingState: Driver<Bool> = isLoading.asDriver()
    
    private (set) lazy var showErrorState: Driver<Bool> = Observable
        .merge(accountDetailEvents.errors(), events.errors())
        .do(onNext: { [weak self] error in
            self?.setLoading(loading: false)
        })
        .map { ($0 as? NetworkingError) != .noNetwork }
        .asDriver(onErrorDriveWith: .empty())
    
    private (set) lazy var showNoNetworkState: Driver<Bool> = Observable
        .merge(accountDetailEvents.errors(), events.errors())
        .map { ($0 as? NetworkingError) == .noNetwork }
        .asDriver(onErrorDriveWith: .empty())
    
    private (set) lazy var showEmptyState: Driver<Bool> = appointments
        .map { $0.isEmpty }
        .asDriver(onErrorDriveWith: .empty())
    
    private var accountDetailEvents: Observable<Event<AccountDetail>>!
    private var events: Observable<Event<[Appointment]>>!
    private let isLoading = BehaviorRelay(value: true)
    private var poll: Observable<Void>!
    
    private let fetchAllDataTrigger = PublishSubject<Void>()
    
    required init(initialAppointments: [Appointment]) {
        
        accountDetailEvents = fetchAllDataTrigger
            .toAsyncRequest {
                AccountService.rx.fetchAccountDetails()
        }
        
        events = accountDetailEvents
            .elements()
            .toAsyncRequest {
                AppointmentService.rx.fetchAppointments(accountNumber: $0.accountNumber, premiseNumber: $0.premiseNumber ?? "")
        }.do(onNext: { event in
            self.setLoading(loading: false)
        })
        
        // Poll for appointments
        appointments = events
            .elements()
            .startWith(initialAppointments)
            .share()
    }
    
    func startPolling() -> Observable<Void> {
        return Observable<Int>
            .interval(.seconds(self.pollInterval), scheduler: MainScheduler.instance)
            .startWith(-1)
            .mapTo(())
            .debug("timer")
            .do(onNext: {
                self.fetchAllData()
            }, onSubscribe: {
                self.setLoading(loading: true)
            })
            .mapTo(())
    }
    
    func fetchAllData() {
        fetchAllDataTrigger.onNext(())
    }
    
    private func setLoading(loading: Bool) {
        self.isLoading.accept(loading)
    }
}
