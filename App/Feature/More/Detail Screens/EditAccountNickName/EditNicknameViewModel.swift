//
//  EditNicknameViewModel.swift
//  Mobile
//
//  Created by Majumdar, Amit on 11/06/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

final class EditNicknameViewModel {
    
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    var accountNickName = BehaviorRelay(value: "")
    
    /// A Local variable to track the retrieved account Nick Name used for comparisons
    var storedAccountNickName = ""
    
    /// A Local variable to store account Number
    var accountNumber = ""
    
    /// `EditNicknameViewModel` initializer
    /// - Parameters:
    ///   - accountService: `AccountService` instance
    required init() {
        if AccountsStore.shared.accounts != nil && !AccountsStore.shared.accounts.isEmpty {
            let currentAccount = AccountsStore.shared.currentAccount
            if let accountNickname = currentAccount.accountNickname {
                storedAccountNickName = accountNickname
                accountNumber = currentAccount.accountNumber
                accountNickName.accept(accountNickname)
            }
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
        return !(text == self.storedAccountNickName)
    }
    
    private lazy var fetchTrigger = Observable
           .merge(fetchAccountDetail,
                  RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount),
                  RxNotifications.shared.recentPaymentsUpdated.mapTo(FetchingAccountState.switchAccount))
    
    func fetchAccountDetail(isRefresh: Bool) {
        fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    /// Set Account Nickname
    /// - Parameters:
    ///   - onSuccess: onSuccess Block that will notify success case
    ///   - onError: onError Block that will notify error case
    func setAccountNickname(onSuccess: @escaping () -> Void,
                            onError: @escaping (String) -> Void) {
        AccountService.setAccountNickname(nickname: accountNickName.value, accountNumber: accountNumber) { nicknameResult in
            switch nicknameResult {
            case .success:
                AccountService.fetchAccounts { accountsResult in
                    switch accountsResult {
                    case .success:
                        onSuccess()
                    case .failure(let error):
                        onError(error.description)
                    }
                }
            case .failure(let error):
                onError(error.description)
            }
        }
    }
}
