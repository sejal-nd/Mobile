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
    
    var workDays = BehaviorRelay<[WorkdaysResponse.WorkDay]>(value: [])
    var selectedDate = BehaviorRelay<Date?>(value: nil)
    var accountDetailEvents: Observable<AccountDetail?> { return currentAccountDetails.asObservable() }
    var accountVerificationResponse = BehaviorRelay<StopServiceVerificationResponse?>(value: nil)
    private var currentAccountDetails = BehaviorRelay<AccountDetail?>(value: nil)
    var unauthAccountDetails = BehaviorRelay<UnAuthAccountDetails?>(value: nil)
    var disposeBag = DisposeBag()
    var invalidDateAMI = [String]()
    private (set) lazy var showLoadingState: Observable<Bool> = isLoading.asObservable()
    private let isLoading = BehaviorRelay(value: true)
    private var currentAccountIndex = 0
    var apiError: Observable<Error> { return apiErrorSubject.asObservable()}
    private var apiErrorSubject = PublishSubject<Error>()
    var unauthMoveData: UnauthMoveData?
    var isUnauth: Bool {
        return unauthMoveData?.isUnauthMove ?? false
    }
    init() {
        
        if AccountsStore.shared.currentIndex != nil {
            currentAccountIndex = AccountsStore.shared.currentIndex
        }
    }
    
    func getAccounts(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        self.isLoading.accept(true)
        if let unauthMoveData = unauthMoveData, unauthMoveData.isUnauthMove {
            self.getUnauthAccountDetails(completion: completion)
        } else {
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
    
    // MARK: Unauth APIs
    func getUnauthAccountDetails(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        let accountDetailRequest = AccountDetailsAnonRequest(phoneNumber: unauthMoveData!.phoneNumber, accountNumber: unauthMoveData?.selectedAccountNumber ?? "", identifier: unauthMoveData!.ssn)
        AnonymousService.accountDetailsAnon(request: accountDetailRequest) { [weak self] (result: Result<UnAuthAccountDetails, NetworkingError>) in
            
            switch result {
            case .success(var accountDetails):
                accountDetails.accountNumber = self?.unauthMoveData?.selectedAccountNumber
                self?.unauthMoveData?.accountDetails = accountDetails
                self?.unauthAccountDetails.accept(accountDetails)
                self?.getUnauthAccountVerification(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getUnauthAccountVerification(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        AnonymousService.stopServiceVerification(unauthMoveData: self.unauthMoveData) { [weak self] (result: Result<StopServiceVerificationResponse, NetworkingError>) in
            
            switch result {
            case .success(let verificationResponse):
                self?.accountVerificationResponse.accept(verificationResponse)
                if (self?.workDays.value.count ?? 0) == 0 {
                    self?.getUnauthWorkdays(completion: completion)
                } else {
                    self?.isLoading.accept(false)
                    completion(.success(true))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getUnauthWorkdays(completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        guard let unauthMoveData = unauthMoveData, let accountDetails = unauthMoveData.accountDetails else {
            completion(.failure(NetworkingError.failed))
            return
        }
        
        AnonymousService.fetchWorkdays(accountDetails: accountDetails) { [weak self] (result: Result<WorkdaysResponse, NetworkingError>) in
            guard let `self` = self else { return }
            switch result {
            case .success(let workdaysResponse):
                let validWorkdays = WorkdaysResponse.getValidWorkdays(workdays: workdaysResponse.list, isAMIAccount: self.unauthMoveData?.accountDetails?.isAMIAccount ?? false, isRCDCapable: self.accountVerificationResponse.value?.isRCDCapable ?? false)
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
