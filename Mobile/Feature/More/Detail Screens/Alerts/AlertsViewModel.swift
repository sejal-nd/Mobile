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
    let currentAlerts = BehaviorRelay(value: [PushNotification]())

    func fetchAlertsFromDisk() {
        currentAlerts.accept(AlertsStore.shared.getAlerts(forAccountNumber: AccountsStore.shared.currentAccount.accountNumber))
    }

    private(set) lazy var shouldShowAlertsEmptyState: Driver<Bool> = currentAlerts.asDriver()
        .map { $0.count == 0 }
}
