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


class EditNicknameViewModel {
    
    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    
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
    required init(accountService: AccountService) {
        self.accountService = accountService
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
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !(text == self.storedAccountNickName)
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
        accountService.setAccountNickname(nickname: accountNickName.value, accountNumber: accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.accountService.fetchAccounts()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { __SRD in
                        onSuccess()
                    }, onError: { error in
                        onError(error.localizedDescription)
                    }).disposed(by: self.disposeBag)
            }, onError: { error in
                onError(error.localizedDescription)
            }).disposed(by: disposeBag)
    }
}
