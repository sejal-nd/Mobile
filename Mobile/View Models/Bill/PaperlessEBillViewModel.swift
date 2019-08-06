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
    private var accountService: AccountService
    private var billService: BillService
    
    let initialAccountDetail: Variable<AccountDetail>
    let accounts: Variable<[Account]>
    
    let accountsToEnroll = Variable(Set<String>())
    let accountsToUnenroll = Variable(Set<String>())
    
    let enrollStatesChanged = Variable<Bool>(false)
    
    var allAccountsCheckboxState = Observable<PaperlessEBillAllAccountsCheckboxState>.empty()
    
    let bag = DisposeBag()
    
    init(accountService: AccountService, billService: BillService, initialAccountDetail accountDetail: AccountDetail) {
        self.accountService = accountService
        self.billService = billService
        self.initialAccountDetail = Variable(accountDetail)
        
        switch Environment.shared.opco {
        case .bge:
            self.accounts = Variable([AccountsStore.shared.accounts.filter { accountDetail.accountNumber == $0.accountNumber }.first!])
        case .comEd, .peco:
            self.accounts = Variable(AccountsStore.shared.accounts)
        }
        
        if self.accounts.value.count == 1 {
            if accountDetail.isEBillEnrollment {
                accountsToUnenroll.value.insert(accountDetail.accountNumber)
            } else {
                accountsToEnroll.value.insert(accountDetail.accountNumber)
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
                return self.accountService.fetchAccountDetail(account: account)
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
            .share(replay: 1)
    }()
    
    func submitChanges(onSuccess: @escaping (PaperlessEBillChangedStatus) -> Void, onError: @escaping (String) -> Void) {
        let enrollObservables = accountsToEnroll.value.map {
            billService.enrollPaperlessBilling(accountNumber: $0,
                                               email: initialAccountDetail.value.customerInfo.emailAddress)
                .do(onNext: {GoogleAnalytics.log(event: .eBillEnrollComplete)})
            }
            .doEach { _ in GoogleAnalytics.log(event: .eBillEnrollOffer) }
        
        let unenrollObservables = accountsToUnenroll.value.map {
            billService.unenrollPaperlessBilling(accountNumber: $0)
                .do(onNext: {GoogleAnalytics.log(event: .eBillUnEnrollComplete)})
            }
            .doEach { _ in GoogleAnalytics.log(event: .eBillUnEnrollOffer) }
        
        var changedStatus: PaperlessEBillChangedStatus
        if Environment.shared.opco == .bge {
            changedStatus = !enrollObservables.isEmpty ? .enroll : .unenroll
        } else { // EM-1780 ComEd/PECO should always show Mixed
            changedStatus = .mixed
        }
        
        Observable.from(enrollObservables + unenrollObservables)
            .merge(maxConcurrent: 3)
            .toArray()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { responseArray in
                onSuccess(changedStatus)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: bag)
    }
    
    var footerText: String? {
        if Environment.shared.opco == .bge {
            return nil
        }
        let opcoString = Environment.shared.opco.displayString
        return String.localizedStringWithFormat("Your enrollment status for Paperless eBill will be updated by the next day.\n\nIf you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through %@.com, you will be automatically unenrolled from MyCheckFree.", opcoString)
    }
    
    func switched(accountDetail: AccountDetail, on: Bool) {
        switch (accountDetail.eBillEnrollStatus, on) {
        case (.canUnenroll, true):
            accountsToUnenroll.value.remove(accountDetail.accountNumber)
        case (.canUnenroll, false):
            accountsToUnenroll.value.insert(accountDetail.accountNumber)
        case (.canEnroll, true):
            accountsToEnroll.value.insert(accountDetail.accountNumber)
        case (.canEnroll, false):
            accountsToEnroll.value.remove(accountDetail.accountNumber)
        default:
            break
        }
    }
    
    private(set) lazy var isSingleAccount: Driver<Bool> = self.accounts.asDriver().map { $0.count == 1 }

}
