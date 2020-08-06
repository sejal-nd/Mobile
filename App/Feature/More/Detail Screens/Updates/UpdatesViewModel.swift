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

    let reloadTableViewEvent = PublishSubject<Void>()
    let a11yScreenChangedEvent = PublishSubject<Void>()

    let selectedSegmentIndex = BehaviorRelay(value: 0)

    let isFetchingUpdates = BehaviorRelay(value: false)
    let isUpdatesError = BehaviorRelay(value: false)
    let isNoNetworkConnection = BehaviorRelay(value: false)

    var currentOpcoUpdates = BehaviorRelay<[Alert]?>(value: nil)

    /// Should Succeed allows us to unit test a failure
    func fetchData() {
        isFetchingUpdates.accept(true)
        isUpdatesError.accept(false)
        isNoNetworkConnection.accept(false)
        
        AlertService.fetchAlertBanner(bannerOnly: false, stormOnly: false) { [weak self] result in
            switch result {
            case .success(let updates):
                self?.currentOpcoUpdates.accept(updates)
                self?.isFetchingUpdates.accept(false)
                self?.isNoNetworkConnection.accept(false)
                self?.reloadTableViewEvent.onNext(())
                self?.a11yScreenChangedEvent.onNext(())
            case .failure(let error):
                self?.isFetchingUpdates.accept(false)
                self?.isUpdatesError.accept(true)
                if error == .noNetwork {
                    self?.isNoNetworkConnection.accept(true)
                }
            }
        }
    }

    private(set) lazy var shouldShowLoadingIndicator: Driver<Bool> = self.isFetchingUpdates.asDriver()

    private(set) lazy var shouldShowErrorLabel: Driver<Bool> =
        Driver.combineLatest(self.isUpdatesError.asDriver(), self.isNoNetworkConnection.asDriver()) { [weak self] in
            return $0 && !$1
    }

    private(set) lazy var shouldShowNoNetworkConnectionView: Driver<Bool> = self.isNoNetworkConnection.asDriver()

    private(set) lazy var shouldShowTableView: Driver<Bool> = self.isUpdatesError.asDriver().not()

    private(set) lazy var shouldShowUpdatesEmptyState: Driver<Bool> =
        Driver.combineLatest(self.isFetchingUpdates.asDriver(), self.isUpdatesError.asDriver(), self.currentOpcoUpdates.asDriver()) {
            guard let opcoUpdates = $2 else { return false }
            return !$0 && !$1 && opcoUpdates.count == 0
    }

}
