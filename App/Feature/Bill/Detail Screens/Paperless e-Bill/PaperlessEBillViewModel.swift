//
//  PaperlessEBillViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

enum PaperlessEBillChangedStatus {
    case enroll
    case unenroll
    case mixed
}

enum PaperlessEBillAllAccountsCheckboxState {
    case checked
    case unchecked
    case indeterminate
}

class PaperlessEBillViewModel {
    let initialAccountDetail: BehaviorRelay<AccountDetail>
    let accounts: BehaviorRelay<[Account]>
    
    let accountsToEnroll = BehaviorRelay(value: Set<String>())
    let accountsToUnenroll = BehaviorRelay(value: Set<String>())
    
    let enrollStatesChanged = BehaviorRelay<Bool>(value: false)
    
    var allAccountsCheckboxState = Observable<PaperlessEBillAllAccountsCheckboxState>.empty()
    
    let bag = DisposeBag()
    
    init(initialAccountDetail accountDetail: AccountDetail) {
        self.initialAccountDetail = BehaviorRelay(value: accountDetail)
        
        switch Configuration.shared.opco {
        case .bge:
            self.accounts = BehaviorRelay(value: [AccountsStore.shared.accounts.filter { accountDetail.accountNumber == $0.accountNumber }.first!])
        case .ace, .comEd, .delmarva, .peco, .pepco:
            self.accounts = BehaviorRelay(value: AccountsStore.shared.accounts)
        }
        
        if self.accounts.value.count == 1 {
            if accountDetail.isEBillEnrollment {
                var newValue = accountsToUnenroll.value
                newValue.insert(accountDetail.accountNumber)
                accountsToUnenroll.accept(newValue)
            } else {
                var newValue = accountsToEnroll.value
                newValue.insert(accountDetail.accountNumber)
                accountsToEnroll.accept(newValue)
            }
        } else {
            Driver.combineLatest(accountsToEnroll.asDriver(), accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
                .drive(enrollStatesChanged)
                .disposed(by: bag)
        }
        
        allAccountsCheckboxState = Observable.combineLatest(accountDetails.asObservable(),
                                                            accountsToEnroll.asObservable(),
                                                            accountsToUnenroll.asObservable())
        { allAccountDetails, toEnroll, toUnenroll -> PaperlessEBillAllAccountsCheckboxState in
            let enrollableAccounts = allAccountDetails.filter { $0.eBillEnrollStatus == .canEnroll }
            let unenrollableAccounts = allAccountDetails.filter { $0.eBillEnrollStatus == .canUnenroll }
            if toEnroll.count == enrollableAccounts.count && toUnenroll.isEmpty {
                return .checked
            } else if toUnenroll.count == unenrollableAccounts.count && toEnroll.isEmpty {
                return .unchecked
            }
            return .indeterminate
        }
    }
    
    lazy var accountDetails: Observable<[AccountDetail]> = {
        let accounts = self.accounts.value
        
        let accountResults = accounts.enumerated()
            .map { index, account -> Observable<AccountDetail> in
                if self.initialAccountDetail.value.accountNumber == account.accountNumber {
                    return Observable.just(self.initialAccountDetail.value)
                }
                return AccountService.rx.fetchAccountDetails(accountNumber: account.accountNumber)
                    .retry(2)
                    .map { $0 }
                    .catchErrorJustReturn(nil)
                    .unwrap()
            }
        
        return Observable.from(accountResults)
            .merge(maxConcurrent: 3)
            .toArray()
        // Re-sort the returned array of account details to match the original order of the accounts passed in.
        // This is done in case one request was fired after, but returned before another
            .map { accountDetails in
                accountDetails
                    .map { detail -> (Int, AccountDetail) in
                        let idx = accounts.firstIndex { $0.accountNumber == detail.accountNumber }
                        guard let index = idx else {
                            return (.max, detail)
                        }
                        return  (index, detail)
                    }
                    .sorted { $0.0 < $1.0 }
                    .map { $0.1 }
            }
            .asObservable()
            .share(replay: 1)
    }()
    
    func submitChanges(onSuccess: @escaping (PaperlessEBillChangedStatus) -> Void, onError: @escaping (String) -> Void) {
        let enrollObservables = accountsToEnroll.value.map {
            BillService.rx.enrollPaperlessBilling(accountNumber: $0,
                                                  email: initialAccountDetail.value.customerInfo.emailAddress)
            .do(onCompleted: {
                FirebaseUtility.logEvent(.eBill(parameters: [.enroll_complete]))
            }, onSubscribe: {
                FirebaseUtility.logEvent(.eBill(parameters: [.enroll_start]))
            })
                }
            .doEach { _ in
                 }
        
        let unenrollObservables = accountsToUnenroll.value.map {
            BillService.rx.unenrollPaperlessBilling(accountNumber: $0)
                .do(onCompleted: {
                    FirebaseUtility.logEvent(.eBill(parameters: [.unenroll_complete]))
                }, onSubscribe: {
                    FirebaseUtility.logEvent(.eBill(parameters: [.unenroll_start]))
                })
        }
            .doEach { _ in
                 }
        
        var changedStatus: PaperlessEBillChangedStatus
        if Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI {
            changedStatus = !enrollObservables.isEmpty ? .enroll : .unenroll
        } else { // EM-1780 ComEd/PECO should always show Mixed
            changedStatus = .mixed
        }
        
        Observable.from(enrollObservables + unenrollObservables)
            .merge(maxConcurrent: 3)
            .toArray()
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { [weak self] responseArray in
                if Configuration.shared.opco.isPHI {
                    let opcoIdentifier = AccountsStore.shared.currentAccount.utilityCode?.uppercased() ?? Configuration.shared.opco.rawValue
                    let billReadyProgramName = "Bill is Ready" + " " + opcoIdentifier
                    let alertPreferencesRequest = AlertPreferencesRequest(alertPreferenceRequests: [AlertPreferencesRequest.AlertRequest(isActive: true, type: "push", programName: billReadyProgramName)])
                    if let accountNumber = self?.initialAccountDetail.value.accountNumber {
                        AlertService.setAlertPreferences(accountNumber: accountNumber,
                                                         request: alertPreferencesRequest) { alertResult in
                            switch alertResult {
                            case .success:
                                onSuccess(changedStatus)
                                Log.info("Enrolled in Bill Is Ready push notification")
                            case .failure(let error):
                                onError(error.description)
                                Log.info("Failed to enroll in Bill Is Ready push notification")
                            }
                            onSuccess(changedStatus)
                        }
                    } else {
                        onSuccess(changedStatus)
                    }
                } else {
                    onSuccess(changedStatus)
                }
            }, onError: { error in
                guard let networkingError = error as? NetworkingError else {
                    onError("Please try again later.")
                    return
                }
                onError(networkingError.description)
            })
            .disposed(by: bag)
    }
    
    var footerText: String? {
        if Configuration.shared.opco == .bge || Configuration.shared.opco.isPHI {
            return nil
        }
        let opcoString = Configuration.shared.opco.displayString
        return String.localizedStringWithFormat("Your enrollment status may take up to 24 hours to update and may not be reflected immediately.\n\nIf you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through %@.com, you will be automatically unenrolled from MyCheckFree.", opcoString)
    }
    
    func switched(accountDetail: AccountDetail, on: Bool) {
        switch (accountDetail.eBillEnrollStatus, on) {
        case (.canUnenroll, true):
            var newValue = accountsToUnenroll.value
            newValue.remove(accountDetail.accountNumber)
            accountsToUnenroll.accept(newValue)
        case (.canUnenroll, false):
            var newValue = accountsToUnenroll.value
            newValue.insert(accountDetail.accountNumber)
            accountsToUnenroll.accept(newValue)
        case (.canEnroll, true):
            var newValue = accountsToEnroll.value
            newValue.insert(accountDetail.accountNumber)
            accountsToEnroll.accept(newValue)
        case (.canEnroll, false):
            var newValue = accountsToEnroll.value
            newValue.remove(accountDetail.accountNumber)
            accountsToEnroll.accept(newValue)
        default:
            break
        }
    }
    
    private(set) lazy var isSingleAccount: Driver<Bool> = self.accounts.asDriver().map { $0.count == 1 }
    
}
