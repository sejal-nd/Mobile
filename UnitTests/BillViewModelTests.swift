//
//  BillViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class BillViewModelTests: XCTestCase {
    
    var viewModel: BillViewModel!
    var accountService: MockAccountService!
    let disposeBag = DisposeBag()
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        
        let mockAccounts = [
            Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!,
            Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"])!,
            Account.from(["accountNumber": "7003238921", "address": "E. Andre Street"])!,
            Account.from(["accountNumber": "5591032201", "address": "7700 Presidents Street"])!,
            Account.from(["accountNumber": "5591032202", "address": "7701 Presidents Street"])!,
            Account.from(["accountNumber": "5591032203", "address": "7702 Presidents Street"])!,
            Account.from(["accountNumber": "5591032204", "address": "7703 Presidents Street"])!,
            Account.from(["accountNumber": "5591032205", "address": "7704 Presidents Street"])!,
            Account.from(["accountNumber": "5591032206", "address": "7705 Presidents Street"])!
        ]
        
        AccountsStore.shared.accounts = mockAccounts
        AccountsStore.shared.currentIndex = 0
        
        accountService = MockAccountService()
        viewModel = BillViewModel(accountService: accountService, authService: MockAuthenticationService())
        scheduler = TestScheduler(initialClock: 0)
    }
    
    func simulateRefreshPulls(at times: [Int]) {
        let events: [Recorded<Event<FetchingAccountState>>] = times.map { next($0, .refresh) }
        let refreshPulls = scheduler.createHotObservable(events)
        refreshPulls.bind(to: viewModel.fetchAccountDetail).disposed(by: disposeBag)
    }
    
    func simulateAccountSwitches(at times: [Int]) {
        let events: [Recorded<Event<Int>>] = zip(times, Array(0..<AccountsStore.shared.accounts.count))
            .map(next)
        
        let accountSwitches = scheduler.createHotObservable(events)
        accountSwitches
            .do(onNext: {
                AccountsStore.shared.currentIndex = $0
            })
            .map { _ in FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchAccountDetail)
            .disposed(by: disposeBag)
    }
    
}

