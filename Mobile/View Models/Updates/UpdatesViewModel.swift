//
//  UpdatesViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UpdatesViewModel {

    let disposeBag = DisposeBag()

    let reloadUpdatesTableViewEvent = PublishSubject<Void>()
    let a11yScreenChangedEvent = PublishSubject<Void>()

    let alertsService: AlertsService

    let selectedSegmentIndex = Variable(0)

    let isFetchingUpdates = Variable(false)
    let isUpdatesError = Variable(false)
    let isNoNetworkConnection = Variable(false)

    var currentOpcoUpdates = Variable<[OpcoUpdate]?>(nil)

    required init(alertsService: AlertsService) {
        self.alertsService = alertsService
    }

    func fetchData() {
        isFetchingUpdates.value = true
        isUpdatesError.value = false
        isNoNetworkConnection.value = false

//        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] accountDetail in
//                guard let `self` = self else { return }
//                self.currentAccountDetail = accountDetail
//                self.isFetchingAccountDetail.value = false
//                self.isNoNetworkConnection.value = false
//                self.a11yScreenChangedEvent.onNext(())
        self.alertsService.fetchOpcoUpdates()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] opcoUpdates in
                self?.currentOpcoUpdates.value = opcoUpdates
                self?.isFetchingUpdates.value = false
                self?.isNoNetworkConnection.value = false
                self?.reloadUpdatesTableViewEvent.onNext(())
                self?.a11yScreenChangedEvent.onNext(())
                }, onError: { [weak self] err in
                    self?.isFetchingUpdates.value = false
                    self?.isUpdatesError.value = true
                    if let error = err as? ServiceError {
                        self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
                    }
            }).disposed(by: self.disposeBag)
//                }, onError: { [weak self] err in
//                    self?.isFetchingAccountDetail.value = false
//                    self?.isFetchingUpdates.value = false
//                    self?.isAccountDetailError.value = true
//                    self?.isUpdatesError.value = true
//                    if let error = err as? ServiceError {
//                        self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
//                    }
//            }).disposed(by: disposeBag)
    }

    private(set) lazy var shouldShowLoadingIndicator: Driver<Bool> = self.isFetchingUpdates.asDriver()

    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
        Driver.combineLatest(self.isUpdatesError.asDriver(), self.isNoNetworkConnection.asDriver()) { [weak self] in
            return $0 && !$1
    }

    private(set) lazy var shouldShowNoNetworkConnectionView: Driver<Bool> = self.isNoNetworkConnection.asDriver()

    private(set) lazy var shouldShowUpdatesTableView: Driver<Bool> = self.isUpdatesError.asDriver().not()

    private(set) lazy var shouldShowUpdatesEmptyState: Driver<Bool> =
        Driver.combineLatest(self.isFetchingUpdates.asDriver(), self.isUpdatesError.asDriver(), self.currentOpcoUpdates.asDriver()) {
            guard let opcoUpdates = $2 else { return false }
            return !$0 && !$1 && opcoUpdates.count == 0
    }

}
