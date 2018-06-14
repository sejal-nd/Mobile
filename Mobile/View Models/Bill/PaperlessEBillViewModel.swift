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

class PaperlessEBillViewModel {
    private var accountService: AccountService
    private var billService: BillService
    
    let initialAccountDetail: Variable<AccountDetail>
    let accounts: Variable<[Account]>
    
    let accountsToEnroll = Variable(Set<String>())
    let accountsToUnenroll = Variable(Set<String>())
    
    let enrollStatesChanged = Variable<Bool>(false)
    
    var enrollAllAccounts = Observable<Bool>.empty()
    
    let bag = DisposeBag()
    
    init(accountService: AccountService, billService: BillService, initialAccountDetail initialAccountDetailValue: AccountDetail) {
        self.accountService = accountService
        self.billService = billService
        self.initialAccountDetail = Variable(initialAccountDetailValue)
        
        switch Environment.shared.opco {
        case .bge:
            self.accounts = Variable([AccountsStore.shared.accounts.filter { initialAccountDetailValue.accountNumber == $0.accountNumber }.first!])
        case .comEd, .peco:
            self.accounts = Variable(AccountsStore.shared.accounts)
        }
    
        Driver.combineLatest(accountsToEnroll.asDriver(), accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(enrollStatesChanged)
            .disposed(by: bag)
        
        enrollAllAccounts = Observable.combineLatest(accountDetails.asObservable(),
                                                     accountsToEnroll.asObservable(),
                                                     accountsToUnenroll.asObservable())
        { allAccountDetails, toEnroll, toUnenroll -> Bool in
            let enrollableAccounts = allAccountDetails.filter { $0.eBillEnrollStatus == .canEnroll }
            return toEnroll.count == enrollableAccounts.count && toUnenroll.isEmpty
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
                        let idx = accounts.index { $0.accountNumber == detail.accountNumber }
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
                .do(onNext: {Analytics.log(event: .EBillEnrollComplete)})
            }
            .doEach { _ in Analytics.log(event: .EBillEnrollOffer) }
        
        let unenrollObservables = accountsToUnenroll.value.map {
            billService.unenrollPaperlessBilling(accountNumber: $0)
                .do(onNext: {Analytics.log(event: .EBillUnEnrollComplete)})
            }
            .doEach { _ in Analytics.log(event: .EBillUnEnrollOffer) }
        
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
        switch Environment.shared.opco {
        case .bge:
            return nil
        case .comEd:
            return NSLocalizedString("If you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through ComEd.com, you will be automatically unenrolled from MyCheckFree.", comment: "")
        case .peco:
            return NSLocalizedString("If you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through PECO.com, you will be automatically unenrolled from MyCheckFree.", comment: "")
        }
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
