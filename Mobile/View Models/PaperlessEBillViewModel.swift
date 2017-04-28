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
    
    var accountDetails: Observable<[AccountDetail]> {
        let accountResults = accounts.value
            .map { account -> Observable<AccountDetail> in
                if initialAccountDetail.value.accountNumber == account.accountNumber {
                    return Observable.just(initialAccountDetail.value)
                }
                return accountService.fetchAccountDetail(account: account)
        }
        return Observable.combineLatest(accountResults) { $0 }
    }
    
    init(accountService: AccountService, initialAccountDetail initialAccountDetailValue: AccountDetail, accounts accountsValue: [Account]) {
        self.accountService = accountService
        self.initialAccountDetail = Variable(initialAccountDetailValue)
        self.accounts = Variable(accountsValue)
        
        Driver.combineLatest(accountsToEnroll.asDriver(), accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(enrollStatesChanged)
            .addDisposableTo(bag)
        
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
        if accountDetail.eBillEnrollStatus == .canUnenroll {
            if on {
                accountsToUnenroll.value.remove(accountDetail.accountNumber)
            } else {
                accountsToUnenroll.value.insert(accountDetail.accountNumber)
            }
        } else {
            if on {
                accountsToEnroll.value.insert(accountDetail.accountNumber)
            } else {
                accountsToEnroll.value.remove(accountDetail.accountNumber)
            }
        }
    }
    
    func switchAllAccounts(on: Bool) {
        
    }
}
