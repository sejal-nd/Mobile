//
//  PaperlessEBillViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class PaperlessEBillViewModel {
    private var accountService: AccountService
    
    let initialAccountDetail: Variable<AccountDetail>
    let accounts: Variable<[Account]>
    
    let accountsToEnroll = Variable(Set<String>())
    let accountsToUnenroll = Variable(Set<String>())
    
    let enrollStatesChanged = Variable<Bool>(false)
    
    var enrollAllAccounts = Observable<Bool>.empty()
    
    let bag = DisposeBag()
    
    let accountDetails: Observable<[AccountDetail]>
    
    init(accountService: AccountService, initialAccountDetail initialAccountDetailValue: AccountDetail, accounts accountsValue: [Account]) {
        self.accountService = accountService
        self.initialAccountDetail = Variable(initialAccountDetailValue)
        
        switch Environment.sharedInstance.opco {
        case .bge:
            self.accounts = Variable([accountsValue.filter { initialAccountDetailValue.accountNumber == $0.accountNumber }.first!])
        case .comEd, .peco:
            self.accounts = Variable(accountsValue)
        }
        
        Driver.combineLatest(accountsToEnroll.asDriver(), accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(enrollStatesChanged)
            .addDisposableTo(bag)
        
        let accountResults = accounts.value.enumerated()
            .map { index, account -> Observable<AccountDetail> in
                if initialAccountDetailValue.accountNumber == account.accountNumber {
                    return Observable.just(initialAccountDetailValue)
                }
                return accountService.fetchAccountDetail(account: account)
                    .do(onNext: {
                        dLog(message: "ACCOUNT LOADED: \($0.accountNumber), \(index)")
                    }, onError: {
                        dLog(message: "ACCOUNT ERROR: \(account.accountNumber), \(index), ERROR: \($0.localizedDescription)")
                    })
        }
        
        accountDetails = Observable.from(accountResults)
            .merge(maxConcurrent: 3)
            .toArray()
            .debug("----------TO ARRAY----------")
            .shareReplay(1)
        
        enrollAllAccounts = Observable.combineLatest(accountDetails.asObservable(),
                                 accountsToEnroll.asObservable(),
                                 accountsToUnenroll.asObservable())
        { allAccountDetails, toEnroll, toUnenroll -> Bool in
            let enrollableAccounts = allAccountDetails.filter { $0.eBillEnrollStatus == .canEnroll }
            return toEnroll.count == enrollableAccounts.count && toUnenroll.isEmpty
        }
    }
    
    var footerText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return nil
        case .comEd:
            return NSLocalizedString("Your enrollment status for paperless ebill will be updated at midnight. If you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through PECO.com, you will be automatically unenrolled from MyCheckFree", comment: "")
        case .peco:
            return NSLocalizedString("Your enrollment status for paperless ebill will be updated at midnight. If you are currently enrolled in eBill through MyCheckFree.com, by enrolling in Paperless eBill through ComEd.com, you will be automatically unenrolled from MyCheckFree", comment: "")
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
}
