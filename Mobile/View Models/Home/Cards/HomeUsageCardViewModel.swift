//
//  HomeUsageCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift


class HomeUsageCardViewModel {
    
    let disposeBag = DisposeBag()
    
    private let account: Observable<Account>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let usageService: UsageService
    
    private let fetchingTracker: ActivityTracker
    
    required init(withAccount account: Observable<Account>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  fetchingTracker: ActivityTracker) {
        self.account = account
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.fetchingTracker = fetchingTracker
    }

}
