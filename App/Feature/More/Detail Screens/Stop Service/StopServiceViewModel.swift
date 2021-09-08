//
//  StopServiceViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class StopServiceViewModel {

    var getAccountDetailSubject = PublishSubject<Void>()
    var didSelectDate = PublishSubject<Void>()
    private (set) var accountDetailEvents: Observable<Event<AccountDetail>>!

    var disposeBag = DisposeBag()

    init() {
        
        if AccountsStore.shared.accounts.count == 0 {
            AccountService.rx.fetchAccounts()
                .subscribe(onNext: { [weak self]_ in
                    self?.getAccountDetailSubject.onNext(())
                }).disposed(by: disposeBag)

        }
            
        accountDetailEvents = getAccountDetailSubject
            .filter{ AccountsStore.shared.accounts.count > 1 }
            .startWith(LoadingView.show())
            .toAsyncRequest {
                AccountService.rx.fetchAccountDetails()
            }
    }
}
