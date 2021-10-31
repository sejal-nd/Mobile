//
//  ScheduleMoveServiceViewModel.swift
//  Mobile
//
//  Created by RAMAITHANI on 01/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ScheduleMoveServiceViewModel {
    
    var getAccountDetailSubject = PublishSubject<Void>()
    var getAccountListSubject = PublishSubject<Void>()
    var workDays = BehaviorRelay<[WorkdaysResponse.WorkDay]>(value: [])
    var selectedDate = BehaviorRelay<Date?>(value: nil)
    var accountDetailEvents: Observable<AccountDetail?> { return currentAccountDetails.asObservable() }
    var accountVerificationResponse = BehaviorRelay<StopServiceVerificationResponse?>(value: nil)
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
    }
    
    func getAccounts(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        self.isLoading.accept(true)
        if AccountsStore.shared.accounts != nil {
            self.getAccountDetails(completion: completion)
        } else {
            AccountService.fetchAccounts { [weak self] result in
                if AccountsStore.shared.accounts != nil {
                    AccountsStore.shared.currentIndex = self?.currentAccountIndex ?? 0
                }
                self?.getAccountDetails(completion: completion)
            }
        }
    }
    
    private func getAccountDetails(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        AccountService.fetchAccountDetails { [weak self] (result: Result<AccountDetail, NetworkingError>) in
            
            switch result {
            case .success(let accountDetails):
                self?.currentAccountDetails.accept(accountDetails)
                if accountDetails.isFinaled {
                    self?.isLoading.accept(false)
                    completion(.success(true))
                    return
                }
                self?.getAccountVerification(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getAccountVerification(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        StopService.stopServiceVerification { [weak self] (result: Result<StopServiceVerificationResponse, NetworkingError>) in
            
            switch result {
            case .success(let verificationResponse):
                self?.accountVerificationResponse.accept(verificationResponse)
                if (self?.workDays.value.count ?? 0) == 0 {
                    self?.getWorkdays(completion: completion)
                } else {
                    self?.isLoading.accept(false)
                    completion(.success(true))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getWorkdays(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        StopService.fetchWorkdays { [weak self] (result: Result<WorkdaysResponse, NetworkingError>) in
            
            switch result {
            case .success(let workdaysResponse):
                self?.workDays.accept(workdaysResponse.list)
                self?.isLoading.accept(false)
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        guard let accountDetails = self.currentAccountDetails.value else { return false }
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        if !accountDetails.isAMIAccount {
            let firstDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 0, to: Date.now)!)
            let secondDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date.now)!)
            let thirdDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 2, to: Date.now)!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return self.workDays.value.contains { $0.value == calendarDate}
    }
}
