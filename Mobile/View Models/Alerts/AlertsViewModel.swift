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
    
    let reloadTableViewEvent = PublishSubject<Void>()
    
    let accountService: AccountService
    let alertsService: AlertsService
    
    let selectedSegmentIndex = Variable(0)
    
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    var currentAccountDetail: AccountDetail?
    var currentOpcoUpdates: [OpcoUpdate]?
    
    required init(accountService: AccountService, alertsService: AlertsService) {
        self.accountService = accountService
        self.alertsService = alertsService
    }
    
    func fetchData() {
        isFetching.value = true
        isError.value = false
        
        accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                self.currentAccountDetail = accountDetail
                self.alertsService.fetchOpcoUpdates(accountDetail: accountDetail)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] opcoUpdates in
                        self?.currentOpcoUpdates = opcoUpdates
                        self?.isFetching.value = false
                        self?.reloadTableViewEvent.onNext()
                    }, onError: { [weak self] err in
                        self?.isFetching.value = false
                        //self?.isError.value = true
                    }).disposed(by: self.disposeBag)
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
    
    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver()) { [weak self] in
            if $0 == 1 && !$1 && self?.currentOpcoUpdates == nil {
                return true
            }
            return !$1 && $2
        }
    
    private(set) lazy var backgroundViewColor: Driver<UIColor> = self.selectedSegmentIndex.asDriver().map {
        $0 == 0 ? .white : .softGray
    }
    

}
