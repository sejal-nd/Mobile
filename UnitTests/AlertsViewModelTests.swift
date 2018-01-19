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
    
    func testShouldShowErrorLabel() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 0
        viewModel.isAccountDetailError.value = true
        viewModel.shouldShowErrorLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Error label should show when Alerts tab is selected and fetching account detail failed")
            }
        }).disposed(by: disposeBag)

        viewModel.selectedSegmentIndex.value = 1
        viewModel.isUpdatesError.value = true
        viewModel.shouldShowErrorLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Error label should show when Updates tab is selected and fetching updates failed")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowAlertsTableView() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 0
        viewModel.isFetchingAccountDetail.value = false
        viewModel.isAccountDetailError.value = false
        viewModel.shouldShowAlertsTableView.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts table view should show when Alerts tab is selected and we successfully fetched account detail")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowAlertsEmptyState() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 0
        viewModel.isFetchingAccountDetail.value = false
        viewModel.isAccountDetailError.value = false
        viewModel.shouldShowAlertsEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts empty should show when Alerts tab is selected and we successfully fetched 0 push notifications from account detail")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowUpdatesTableView() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 1
        viewModel.isFetchingUpdates.value = false
        viewModel.isUpdatesError.value = false
        viewModel.shouldShowUpdatesTableView.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Updates table view should show when Updates tab is selected and we successfully fetched updates")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowUpdatesEmptyState() {
        viewModel = AlertsViewModel(accountService: MockAccountService(), alertsService: MockAlertsService())
        viewModel.selectedSegmentIndex.value = 1
        viewModel.isFetchingUpdates.value = false
        viewModel.isUpdatesError.value = false
        viewModel.currentOpcoUpdates.value = [OpcoUpdate]()
        viewModel.shouldShowUpdatesEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Updates empty should show when Updates tab is selected and we successfully fetched 0 updates")
            }
        }).disposed(by: disposeBag)
    }
}
