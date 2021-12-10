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

    var workDays = BehaviorRelay<[WorkdaysResponse.WorkDay]>(value: [])
    var selectedDate = BehaviorRelay<Date?>(value: nil)
    var accountDetailEvents: Observable<AccountDetail?> { return currentAccountDetails.asObservable() }
    private var currentAccountDetails = BehaviorRelay<AccountDetail?>(value: nil)
    var accountVerificationResponse = BehaviorRelay<StopServiceVerificationResponse?>(value: nil)
    var disposeBag = DisposeBag()
    var invalidDateAMI = [String]()
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    private let isLoading = BehaviorRelay(value: true)
    private var currentAccountIndex = 0

    init() {
        
        if AccountsStore.shared.currentIndex != nil {
            currentAccountIndex = AccountsStore.shared.currentIndex
        }
    }
    
    func getAccounts(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        self.isLoading.accept(true)
        if AccountsStore.shared.accounts != nil {
            self.getAccountDetails { [weak self] result in
                switch result {
                case .success:
                    self?.isLoading.accept(false)
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            AccountService.fetchAccounts { [weak self] result in
                switch result {
                case .success:
                    if AccountsStore.shared.accounts != nil {
                        AccountsStore.shared.currentIndex = self?.currentAccountIndex ?? 0
                    }
                    self?.isLoading.accept(false)
                    self?.getAccountDetails(completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func getAccountDetails(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        AccountService.fetchAccountDetails(isGetRCDCapable: true) { [weak self] (result: Result<AccountDetail, NetworkingError>) in
            
            switch result {
            case .success(let accountDetails):
                self?.currentAccountDetails.accept(accountDetails)
                if accountDetails.isFinaled {
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
                    completion(.success(true))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getWorkdays(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        StopService.fetchWorkdays { [weak self] (result: Result<WorkdaysResponse, NetworkingError>) in
            guard let `self` = self, let accountDetails = self.currentAccountDetails.value else { return }
            switch result {
            case .success(let workdaysResponse):
                let validWorkdays = WorkdaysResponse.getValidWorkdays(workdays: workdaysResponse.list, isAMIAccount: accountDetails.isAMIAccount, isRCDCapable: accountDetails.isRCDCapable)
                self.workDays.accept(validWorkdays)
                self.isLoading.accept(false)
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isValidDate(_ date: Date)-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        return self.workDays.value.contains { $0.value == calendarDate}
    }
}
