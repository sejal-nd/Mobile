//
//  AlertsViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewModel {

    let disposeBag = DisposeBag()

    let reloadAlertsTableViewEvent = PublishSubject<Void>()
    let a11yScreenChangedEvent = PublishSubject<Void>()

    let accountService: AccountService

    let selectedSegmentIndex = Variable(0)

    let isFetchingAccountDetail = Variable(false)
    let isAccountDetailError = Variable(false)
    let isNoNetworkConnection = Variable(false)

    var currentAccountDetail: AccountDetail?
    var currentAlerts = Variable([PushNotification]())

    required init(accountService: AccountService) {
        self.accountService = accountService
    }

    func fetchData() {
        isFetchingAccountDetail.value = true
        isAccountDetailError.value = false
        isNoNetworkConnection.value = false

        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let `self` = self else { return }
                self.currentAccountDetail = accountDetail
                self.isFetchingAccountDetail.value = false
                self.isNoNetworkConnection.value = false
                self.a11yScreenChangedEvent.onNext(())
                }, onError: { [weak self] err in
                    self?.isFetchingAccountDetail.value = false
                    self?.isAccountDetailError.value = true
                    if let error = err as? ServiceError {
                        self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
                    }
            }).disposed(by: disposeBag)
    }

    func fetchAlertsFromDisk() {
        currentAlerts.value = AlertsStore.shared.getAlerts(forAccountNumber: AccountsStore.shared.currentAccount.accountNumber)
        self.reloadAlertsTableViewEvent.onNext(())
    }

    private(set) lazy var shouldShowLoadingIndicator: Driver<Bool> = self.isFetchingAccountDetail.asDriver()

    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
            Driver.combineLatest(self.isAccountDetailError.asDriver(), self.isNoNetworkConnection.asDriver()) { [weak self] in
                return $0 && !$1
        }

    private(set) lazy var shouldShowNoNetworkConnectionView: Driver<Bool> = self.isNoNetworkConnection.asDriver()

    private(set) lazy var shouldShowAlertsTableView: Driver<Bool> =
        Driver.combineLatest(self.isFetchingAccountDetail.asDriver(), self.isAccountDetailError.asDriver()) {
            return !$0 && !$1
    }

    private(set) lazy var shouldShowAlertsEmptyState: Driver<Bool> =
        Driver.combineLatest(self.isFetchingAccountDetail.asDriver(), self.isAccountDetailError.asDriver(), self.currentAlerts.asDriver(), self.isNoNetworkConnection.asDriver()) {
            return !$0 && !$1 && $2.count == 0 && !$3
    }

}
