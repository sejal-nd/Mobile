//
//  UpdatesViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

//import RxSwift
//import RxCocoa
//
//class UpdatesViewModel {
//
//    let disposeBag = DisposeBag()
//
//    let reloadAlertsTableViewEvent = PublishSubject<Void>()
//    let reloadUpdatesTableViewEvent = PublishSubject<Void>()
//    let a11yScreenChangedEvent = PublishSubject<Void>()
//
//    let accountService: AccountService
//    let alertsService: AlertsService
//
//    let selectedSegmentIndex = Variable(0)
//
//    let isFetchingAccountDetail = Variable(false)
//    let isFetchingUpdates = Variable(false)
//    let isAccountDetailError = Variable(false)
//    let isUpdatesError = Variable(false)
//    let isNoNetworkConnection = Variable(false)
//
//    var currentAccountDetail: AccountDetail?
//    var currentAlerts = Variable([PushNotification]())
//    var currentOpcoUpdates = Variable<[OpcoUpdate]?>(nil)
//
//    required init(accountService: AccountService, alertsService: AlertsService) {
//        self.accountService = accountService
//        self.alertsService = alertsService
//    }
//
//    func fetchData() {
//        isFetchingAccountDetail.value = true
//        isFetchingUpdates.value = true
//        isAccountDetailError.value = false
//        isUpdatesError.value = false
//        isNoNetworkConnection.value = false
//
//        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] accountDetail in
//                guard let `self` = self else { return }
//                self.currentAccountDetail = accountDetail
//                self.isFetchingAccountDetail.value = false
//                self.isNoNetworkConnection.value = false
//                self.a11yScreenChangedEvent.onNext(())
//                self.alertsService.fetchOpcoUpdates(accountDetail: accountDetail)
//                    .observeOn(MainScheduler.instance)
//                    .subscribe(onNext: { [weak self] opcoUpdates in
//                        self?.currentOpcoUpdates.value = opcoUpdates
//                        self?.isFetchingUpdates.value = false
//                        self?.isNoNetworkConnection.value = false
//                        self?.reloadUpdatesTableViewEvent.onNext(())
//                        self?.a11yScreenChangedEvent.onNext(())
//                        }, onError: { [weak self] err in
//                            self?.isFetchingUpdates.value = false
//                            self?.isUpdatesError.value = true
//                            if let error = err as? ServiceError {
//                                self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
//                            }
//                    }).disposed(by: self.disposeBag)
//                }, onError: { [weak self] err in
//                    self?.isFetchingAccountDetail.value = false
//                    self?.isFetchingUpdates.value = false
//                    self?.isAccountDetailError.value = true
//                    self?.isUpdatesError.value = true
//                    if let error = err as? ServiceError {
//                        self?.isNoNetworkConnection.value = error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue
//                    }
//            }).disposed(by: disposeBag)
//    }
//
//    func fetchAlertsFromDisk() {
//        currentAlerts.value = AlertsStore.shared.getAlerts(forAccountNumber: AccountsStore.shared.currentAccount.accountNumber)
//        self.reloadAlertsTableViewEvent.onNext(())
//    }
//
//    private(set) lazy var shouldShowLoadingIndicator: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingAccountDetail.asDriver(), self.isFetchingUpdates.asDriver()) {
//            return ($0 == 0 && $1) || ($0 == 1 && $2)
//    }
//
//    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isAccountDetailError.asDriver(), self.isUpdatesError.asDriver(), self.isNoNetworkConnection.asDriver()) { [weak self] in
//            return (($0 == 0 && $1) || ($0 == 1 && $2)) && !$3
//    }
//
//    private(set) lazy var shouldShowNoNetworkConnectionView: Driver<Bool> = self.isNoNetworkConnection.asDriver()
//
//    private(set) lazy var shouldShowAlertsTableView: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingAccountDetail.asDriver(), self.isAccountDetailError.asDriver()) {
//            return $0 == 0 && !$1 && !$2
//    }
//    
//    private(set) lazy var shouldShowAlertsEmptyState: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingAccountDetail.asDriver(), self.isAccountDetailError.asDriver(), self.currentAlerts.asDriver(), self.isNoNetworkConnection.asDriver()) {
//            return $0 == 0 && !$1 && !$2 && $3.count == 0 && !$4
//    }
//
//    private(set) lazy var shouldShowUpdatesTableView: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingUpdates.asDriver(), self.isUpdatesError.asDriver()) {
//            return $0 == 1 && !$1 && !$2
//    }
//
//    private(set) lazy var shouldShowUpdatesEmptyState: Driver<Bool> =
//        Driver.combineLatest(self.selectedSegmentIndex.asDriver(), self.isFetchingUpdates.asDriver(), self.isUpdatesError.asDriver(), self.currentOpcoUpdates.asDriver()) {
//            guard let opcoUpdates = $3 else { return false }
//            return $0 == 1 && !$1 && !$2 && opcoUpdates.count == 0
//    }
//
//    private(set) lazy var backgroundViewColor: Driver<UIColor> = self.selectedSegmentIndex.asDriver().map {
//        $0 == 0 ? .white : .softGray
//    }
//
//
//}
