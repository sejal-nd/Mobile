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
    let bag = DisposeBag()
    
    let accounts = Variable<[Account]>([])
    let accountsToEnroll = Variable(Set<Account>())
    let enrollAllAccounts = Variable<Bool>(true)
    
    let enrolling = Variable(false)
    let unenrolling = Variable(false)
    
    init() {
        Observable.combineLatest(accounts.asObservable(), accountsToEnroll.asObservable().map(Array.init))
        { accounts, accountsToEnroll in
            accounts.count == accountsToEnroll.count
        }
        .bindTo(enrollAllAccounts)
        .addDisposableTo(bag)
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
}
