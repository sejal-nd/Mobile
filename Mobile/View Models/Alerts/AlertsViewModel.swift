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
    
    let reloadAlertsTableViewEvent = PublishSubject<Void>()
    let reloadUpdatesTableViewEvent = PublishSubject<Void>()
    
    let accountService: AccountService
    let alertsService: AlertsService
    
    let selectedSegmentIndex = Variable(0)
    
    let isFetchingAccountDetail = Variable(false)
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    var currentAccountDetail: AccountDetail?
    var currentAlerts = Variable([PushNotification]())
    var currentOpcoUpdates = Variable<[OpcoUpdate]?>(nil)
    
    required init(accountService: AccountService, alertsService: AlertsService) {
        self.accountService = accountService
        self.alertsService = alertsService
    }
    
    func fetchData() {
        currentAlerts.value = AlertsStore.sharedInstance.getAlerts(forAccountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
        self.reloadAlertsTableViewEvent.onNext()
        
        isFetchingAccountDetail.value = true
        isFetching.value = true
        isError.value = false
        
        accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                self.currentAccountDetail = accountDetail
                self.isFetchingAccountDetail.value = false
                self.alertsService.fetchOpcoUpdates(accountDetail: accountDetail)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] opcoUpdates in
                        self?.currentOpcoUpdates.value = opcoUpdates
                        self?.isFetching.value = false
                        self?.reloadUpdatesTableViewEvent.onNext()
                    }, onError: { [weak self] err in
                        self?.isFetching.value = false
                        self?.isError.value = true
                    }).disposed(by: self.disposeBag)
            }, onError: { [weak self] err in
                self?.isFetchingAccountDetail.value = false
                self?.isFetching.value = false
                self?.isError.value = true
            }).disposed(by: disposeBag)
    }
    
    private(set) lazy var shouldShowLoadingIndicator: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isFetchingAccountDetail.asDriver()) {
            return ($0 == 0 && $2) || ($0 == 1 && $1)
        }
    
    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver()) { [weak self] in
            return $0 == 1 && !$1 && $2
        }
    
    private(set) lazy var shouldShowAlertsTableView: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingAccountDetail.asDriver()) {
            return $0 == 0 && !$1
        }
    
    private(set) lazy var shouldShowAlertsEmptyState: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.currentAlerts.asDriver(), self.isFetchingAccountDetail.asDriver()) {
            return $0 == 0 && $1.count == 0 && !$2
        }
    
    private(set) lazy var shouldShowUpdatesTableView: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver()) {
            return $0 == 1 && !$1 && !$2
        }
    
    private(set) lazy var shouldShowUpdatesEmptyState: Driver<Bool> =
        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetching.asDriver(), self.isError.asDriver(), self.currentOpcoUpdates.asDriver()) { [weak self] in
            guard let opcoUpdates = $3 else { return false }
            return $0 == 1 && !$1 && !$2 && opcoUpdates.count == 0
        }
    
    private(set) lazy var backgroundViewColor: Driver<UIColor> = self.selectedSegmentIndex.asDriver().map {
        $0 == 0 ? .white : .softGray
    }
    

}
