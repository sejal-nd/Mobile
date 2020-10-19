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
    
    
    let loading = BehaviorRelay(value: true)
    let error = BehaviorRelay(value: false)
    let electricChoiceId = BehaviorRelay<String?>(value: nil)
    let gasChoiceId = BehaviorRelay<String?>(value: nil)
    
    init() {

    }
    
    func fetchChoiceIds() {
        electricChoiceId.accept(nil)
        gasChoiceId.accept(nil)
        loading.accept(true)
        
        AccountService.fetchAccountDetails { [weak self] result in
            switch result {
            case .success(let accountDetail):
                self?.loading.accept(false)
                if let elec = accountDetail.electricChoiceID {
                    self?.electricChoiceId.accept(elec)
                }
                if let gas = accountDetail.gasChoiceID {
                    self?.gasChoiceId.accept(gas)
                }
            case .failure:
                self?.loading.accept(false)
                self?.error.accept(true)
                
            }
        }
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
