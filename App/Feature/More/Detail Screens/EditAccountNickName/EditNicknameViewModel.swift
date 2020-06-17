//
//  EditNicknameViewModel.swift
//  BGE
//
//  Created by Majumdar, Amit on 11/06/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt


class EditNicknameViewModel {
    
    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let authService: AuthenticationService
    private let usageService: UsageService
    
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    var accountNickName = BehaviorRelay(value: "")
    
    /// A Local variable to track the retrieved account Nick Name used for comparisons
    var storedAccountNickName = ""
    
    /// `EditNicknameViewModel` initializer
    /// - Parameters:
    ///   - accountService: `AccountService` instance
    ///   - authService: `AuthenticationService` instance
    ///   - usageService: `UsageService` instance
    required init(accountService: AccountService, authService: AuthenticationService, usageService: UsageService) {
        self.accountService = accountService
        self.authService = authService
        self.usageService = usageService

        if AccountsStore.shared.accounts != nil && !AccountsStore.shared.accounts.isEmpty {
            let currentAccount = AccountsStore.shared.currentAccount
            if let accountNickname = currentAccount.accountNickname {
                accountNickName.accept(accountNickname)
            }
            storedAccountNickName = accountNickName.value
        }
    }
    
    private func tracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshTracker
        case .switchAccount: return switchAccountsTracker
        }
    }
    
    private(set) lazy var saveNicknameEnabled: Driver<Bool> = self.accountNickName.asDriver().map { [weak self] text -> Bool in
        guard let self = self else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !(text == self.storedAccountNickName)
    }
    
    private lazy var fetchTrigger = Observable
           .merge(fetchAccountDetail,
                  RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount),
                  RxNotifications.shared.recentPaymentsUpdated.mapTo(FetchingAccountState.switchAccount))
    
    func fetchAccountDetail(isRefresh: Bool) {
        fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
}
