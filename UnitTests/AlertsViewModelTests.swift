//
//  AlertsViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AlertsViewModelTests: XCTestCase {
    
    var viewModel = AlertsViewModel()
    let disposeBag = DisposeBag()
    
    func testShouldShowAlertsEmptyState() {
        viewModel.shouldShowAlertsEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts empty should show when Alerts tab is selected and we successfully fetched 0 push notifications from account detail")
            }
        }).disposed(by: disposeBag)
    }

}
