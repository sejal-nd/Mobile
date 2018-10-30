//
//  AppointmentUnitTests.swift
//  Mobile
//
//  Created by Marc Shilling on 10/30/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AppointmentUnitTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    func testTabTitle() {
        let appointment =
        let viewModel = AppointmentDetailViewModel(appointment: <#T##Appointment#>)
    }
    func testShouldShowAlertsEmptyState() {
        viewModel.shouldShowAlertsEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts empty should show when Alerts tab is selected and we successfully fetched 0 push notifications from account detail")
            }
        }).disposed(by: disposeBag)
    }
    
}
