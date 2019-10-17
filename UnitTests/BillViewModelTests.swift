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
    let scheduler = TestScheduler(initialClock: 0)
    
    override func setUp() {
        super.setUp()
        accountService = MockAccountService()
        viewModel = BillViewModel(accountService: accountService, authService: MockAuthenticationService(), usageService: MockUsageService())
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

