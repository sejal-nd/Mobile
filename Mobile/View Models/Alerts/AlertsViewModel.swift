//
//  AlertsViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountService: AccountService
    
    let selectedSegmentIndex = Variable(0)
    
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    var currentAccountDetail: AccountDetail?
    
    required init(accountService: AccountService) {
        self.accountService = accountService
    }
    
    func fetchAccountDetail() {
        isFetching.value = true
        isError.value = false
        
        accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                self?.currentAccountDetail = accountDetail
                self?.isFetching.value = false
            }, onError: { [weak self] err in
                self?.isFetching.value = false
                self?.isError.value = true
            }).disposed(by: disposeBag)
    }
    
    private(set) lazy var shouldShowAlertsTableView: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver()) {
            return $0 == 0 && !$1 && !$2
        }
    
    private(set) lazy var shouldShowUpdatesTableView: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver()) {
            return $0 == 1 && !$1 && !$2
        }

}
