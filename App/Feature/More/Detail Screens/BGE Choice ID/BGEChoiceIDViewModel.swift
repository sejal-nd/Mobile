//
//  BGEChoiceIDViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BGEChoiceIDViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    
    let loading = BehaviorRelay(value: true)
    let error = BehaviorRelay(value: false)
    let electricChoiceId = BehaviorRelay<String?>(value: nil)
    let gasChoiceId = BehaviorRelay<String?>(value: nil)
    
    init(accountService: AccountService) {
        self.accountService = accountService

    }
    
    func fetchChoiceIds() {
        electricChoiceId.accept(nil)
        gasChoiceId.accept(nil)
        loading.accept(true)
        NewAccountService.rx.fetchAccountDetails()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                self.loading.accept(false)
                if let elec = accountDetail.electricChoiceID {
                    self.electricChoiceId.accept(elec)
                }
                if let gas = accountDetail.gasChoiceID {
                    self.gasChoiceId.accept(gas)
                }
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.error.accept(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    private(set) lazy var shouldShowDividerLine: Driver<Bool> =
        Driver.combineLatest(self.electricChoiceId.asDriver(),
                             self.gasChoiceId.asDriver()) {
            $0 != nil && $1 != nil
        }
    
    private(set) lazy var shouldShowErrorEmptyState: Driver<Bool> =
        Driver.combineLatest(self.error.asDriver(),
                             self.loading.asDriver(),
                             self.electricChoiceId.asDriver(),
                             self.gasChoiceId.asDriver()) {
            $0 || (!$1 && $2 == nil && $3 == nil)
        }
    
}
