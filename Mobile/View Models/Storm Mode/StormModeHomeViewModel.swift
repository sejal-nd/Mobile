//
//  StormModeHomeViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeHomeViewModel {
    
    let stormModePollInterval = 30.0
    
    let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    private(set) lazy var stormModeEnded: Driver<Void> = Observable<Int>
        .interval(stormModePollInterval, scheduler: MainScheduler.instance)
        .toAsyncRequest { [weak self] _ in
            self?.authService.getMaintenanceMode() ?? .empty()
        }
        // Ignore errors and positive storm mode responses
        .elements()
        .filter { !$0.stormModeStatus }
        // Stop polling after storm mode ends
        .take(1)
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
}
