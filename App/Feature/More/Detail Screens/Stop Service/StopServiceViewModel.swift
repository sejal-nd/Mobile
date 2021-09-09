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
    var workDays = BehaviorRelay<[String]>(value: [])
    var selectedDate = BehaviorRelay<Date?>(value: nil)
    var accountDetailEvents: Observable<AccountDetail?> { return currentAccountDetails.asObservable() }
    private var currentAccountDetails = BehaviorRelay<AccountDetail?>(value: nil)
    var disposeBag = DisposeBag()
    var invalidDateAMI = [String]()
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    private let isLoading = BehaviorRelay(value: true)

    init() {
        
        getAccountListSubject
            .toAsyncRequest { AccountService.rx.fetchAccounts() } .subscribe(onNext: { [weak self]_ in
                self?.getAccountDetailSubject.onNext(())
            }).disposed(by: disposeBag)

            
        getAccountDetailSubject
            .toAsyncRequest { [weak self] _ -> Observable<AccountDetail> in
                
                guard let `self` = self else { return Observable.empty() }
                if !self.isLoading.value {
                    self.isLoading.accept(true)
                }
                return AccountService.rx.fetchAccountDetails()
            }.subscribe(onNext: { [weak self] result in
                guard let `self` = self, let accountDetails = result.element else {return }
                self.currentAccountDetails.accept(accountDetails)
                self.isLoading.accept(false)
            }).disposed(by: disposeBag)

        
        StopService.fetchWorkdays { (result: Result<[String], NetworkingError>) in
            switch result {
            case .success(let workDays):
                self.workDays.accept(workDays)
            case .failure:
                break
            }
        }
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        guard let accountDetails = self.currentAccountDetails.value else { return false }
        let calendarDate = DateFormatter.yyyyMMddFormatter.string(from: date)
        if !accountDetails.isAMIAccount {
            let firstDay = DateFormatter.yyyyMMddFormatter.string(from: Date())
            let secondDay = DateFormatter.yyyyMMddFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date())!)
            let thirdDay = DateFormatter.yyyyMMddFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date())!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return self.workDays.value.contains("\(calendarDate)T00:00:00.000Z")
    }
}
