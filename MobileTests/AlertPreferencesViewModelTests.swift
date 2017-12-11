//
//  AlertPreferencesViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AlertPreferencesViewModelTests: XCTestCase {
    
    var viewModel: AlertPreferencesViewModel!
    let disposeBag = DisposeBag()
    
    func testShouldShowContent() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        viewModel.isFetching.value = false
        viewModel.isError.value = false
        viewModel.shouldShowContent.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Content should show when fetch is complete without error")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSaveButtonEnabled() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        viewModel.isFetching.value = false
        viewModel.isError.value = false
        viewModel.userChangedPrefs.value = true
        viewModel.saveButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Save button should be enabled")
            }
        }).disposed(by: disposeBag)
    }
}
