//
//  MoveLandingViewModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 19/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
class MoveLandingViewModel {

    let disposeBag = DisposeBag()
    var isDetailsLoading = false
    var isBeginPressed = false

    var getAccountDetailSubject = PublishSubject<Void>()
    private var currentAccountDetails = BehaviorRelay<AccountDetail?>(value: nil)
    var accountDetailsEvent: Observable<AccountDetail?> { return currentAccountDetails.asObservable()}


    init() {
        getAccountDetailSubject
            .toAsyncRequest { [weak self] _ -> Observable<AccountDetail> in
                guard let self = self else { return Observable.empty()}
                if AccountsStore.shared.accounts != nil {
                    if !self.isDetailsLoading {
                        self.isDetailsLoading = true
                    }
                    return AccountService.rx.fetchAccountDetails()
                }
                return Observable.empty()
            }.subscribe(onNext: { [weak self] result in
                guard let `self` = self, let accountDetails = result.element else {return }
                if self.isDetailsLoading {
                    self.isDetailsLoading = false
               }
                self.currentAccountDetails.accept(accountDetails)
            }).disposed(by: disposeBag)
    }

    func fetchAccountDetails(){
        getAccountDetailSubject.onNext(())
    }

    func getAccountDetails() -> AccountDetail?{
        return currentAccountDetails.value
    }

    let moveCommercialServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .bge:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/accounts/login?TARGET=/CustomerServices/service/move")
        default:
            return nil
        }
    }()
}
