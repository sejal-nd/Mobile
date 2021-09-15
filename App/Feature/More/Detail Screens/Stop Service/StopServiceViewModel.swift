//
//  StopServiceViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class StopServiceViewModel {

    var getAccountDetailSubject = PublishSubject<Void>()
    var getAccountListSubject = PublishSubject<Void>()
    var workDays = BehaviorRelay<[WorkdaysResponse.WorkDay]>(value: [])
    var selectedDate = BehaviorRelay<Date?>(value: nil)
    var accountDetailEvents: Observable<AccountDetail?> { return currentAccountDetails.asObservable() }
    private var currentAccountDetails = BehaviorRelay<AccountDetail?>(value: nil)
    var disposeBag = DisposeBag()
    var invalidDateAMI = [String]()
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    private let isLoading = BehaviorRelay(value: true)
    private var getWorkdays = PublishSubject<Void>()
    private var currentAccountIndex = 0

    init() {
        
        if AccountsStore.shared.currentIndex != nil {
            currentAccountIndex = AccountsStore.shared.currentIndex
        }
        getAccountListSubject
            .toAsyncRequest { AccountService.rx.fetchAccounts() } .subscribe(onNext: { [weak self] result in
                if AccountsStore.shared.accounts != nil {
                    AccountsStore.shared.currentIndex = self?.currentAccountIndex ?? 0
                }
                self?.getAccountDetailSubject.onNext(())
                self?.getWorkdays.onNext(())
            }).disposed(by: disposeBag)

            
        getAccountDetailSubject
            .toAsyncRequest { [weak self] _ -> Observable<AccountDetail> in
                
                guard let `self` = self else { return Observable.empty() }
                if !self.isLoading.value {
                    self.isLoading.accept(true)
                }
                if AccountsStore.shared.accounts != nil {
                    return AccountService.rx.fetchAccountDetails()
                }
                return Observable.empty()
            }.subscribe(onNext: { [weak self] result in
                guard let `self` = self, let accountDetails = result.element else {return }
                self.currentAccountDetails.accept(accountDetails)
                self.isLoading.accept(false)
            }).disposed(by: disposeBag)

        
        getWorkdays
            .toAsyncRequest { [weak self] _ -> Observable<WorkdaysResponse> in
                
                guard let `self` = self else { return Observable.empty() }
                if !self.isLoading.value {
                    self.isLoading.accept(true)
                }
                return StopService.rx.fetchWorkdays()
            }.subscribe(onNext: { [weak self] result in
                guard let `self` = self, let workdaysResponse = result.element else {return }
                self.workDays.accept(workdaysResponse.list)
            }).disposed(by: disposeBag)
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        guard let accountDetails = self.currentAccountDetails.value else { return false }
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        if !accountDetails.isAMIAccount {
            let firstDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 0, to: Date())!)
            let secondDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date())!)
            let thirdDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 2, to: Date())!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return self.workDays.value.contains { $0.value == calendarDate}
    }
}
