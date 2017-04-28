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
    let accountsIneligible = Variable(Set<String>())
    let accountsFinaled = Variable(Set<String>())
    
    let enrollStatesChanged = Variable<Bool>(false)
    
    let enrollAllAccounts = Variable<Bool>(true)
    
    let bag = DisposeBag()
    
    init(accountService: AccountService, initialAccountDetail initialAccountDetailValue: AccountDetail, accounts accountsValue: [Account]) {
        self.accountService = accountService
        self.initialAccountDetail = Variable(initialAccountDetailValue)
        self.accounts = Variable(accountsValue)
        
        Driver.combineLatest(accountsToEnroll.asDriver(), accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(enrollStatesChanged)
            .addDisposableTo(bag)
        
        let accountsUpdated = accountDetails.asObservable().share()
        
        accountsUpdated
            .map { accounts -> [String] in
                accounts
                    .filter { $0.eBillEnrollStatus == .ineligible }
                    .map { $0.accountNumber }
            }
            .map(Set.init)
            .bindTo(accountsIneligible)
            .addDisposableTo(bag)
        
        accountsUpdated
            .map { accounts -> [String] in
                accounts
                    .filter { $0.eBillEnrollStatus == .finaled  }
                    .map { $0.accountNumber }
            }
            .map(Set.init)
            .bindTo(accountsFinaled)
            .addDisposableTo(bag)
        
        
        Observable.combineLatest(accounts.asObservable(),
                                 accountsToEnroll.asObservable(),
                                 accountsToUnenroll.asObservable(),
                                 accountsIneligible.asObservable(),
                                 accountsFinaled.asObservable())
        { allAccounts, accountsToEnroll, accountsToUnenroll, accountsIneligible, accountsFinaled -> Bool in
            allAccounts.count - accountsToUnenroll.count == [accountsToEnroll, accountsIneligible, accountsFinaled].reduce(0) { $0 + $1.count }
        }
            .debug("enrollAllAccounts")
            .bindTo(enrollAllAccounts)
            .addDisposableTo(bag)
    }
    
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
}
