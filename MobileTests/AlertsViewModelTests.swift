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
    
    var viewModel: AlertsViewModel!
    let disposeBag = DisposeBag()
    
    func testShouldShowLoadingIndicator() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 0
        viewModel.isFetchingAccountDetail.value = true
        viewModel.shouldShowLoadingIndicator.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Loading indicator should show when Alerts tab is selected while fetching account detail")
            }
        }).disposed(by: disposeBag)
        
        viewModel.selectedSegmentIndex.value = 1
        viewModel.isFetchingUpdates.value = true
        viewModel.shouldShowLoadingIndicator.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Loading indicator should show when Updates tab is selected while fetching updates")
            }
        }).disposed(by: disposeBag)
    }
}
