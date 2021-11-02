//
//  ScheduleMoveServiceViewModelTests.swift
//  UnitTests
//
//  Created by RAMAITHANI on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class ScheduleMoveServiceViewModelTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidDateAMIUser() throws {
        
        let viewModel = ScheduleMoveServiceViewModel()
        KeychainController.default.set("default", forKey: .tokenKeychainKey)

        let expectation = expectation(description: "API Response Expectation")
        viewModel.getAccounts { (result: Result<Bool, NetworkingError>) in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 120, handler: nil)

        XCTAssertNotNil(AccountsStore.shared.accounts)
        XCTAssertTrue(AccountsStore.shared.accounts.count > 0)
        XCTAssertNotNil(AccountsStore.shared.currentAccount)
        XCTAssertNotNil(AccountsStore.shared.currentIndex)

        let today = DateFormatter.mmDdYyyyFormatter.date(from: "10/07/2021")
        let yesterday = DateFormatter.mmDdYyyyFormatter.date(from: "10/06/2021")
        let tomorrow = DateFormatter.mmDdYyyyFormatter.date(from: "10/08/2021")
        let dayAfterTomorrow = DateFormatter.mmDdYyyyFormatter.date(from: "10/09/2021")
        XCTAssertFalse(viewModel.isValidDate(yesterday!))
        XCTAssertTrue(viewModel.isValidDate(today!))
        XCTAssertTrue(viewModel.isValidDate(tomorrow!))
        XCTAssertTrue(viewModel.isValidDate(dayAfterTomorrow!))
    }
    
    func testValidDateNonAMIUser() throws {
        
        let viewModel = ScheduleMoveServiceViewModel()
        KeychainController.default.set("nonAMIUser", forKey: .tokenKeychainKey)

        let expectation = expectation(description: "API Response Expectation")
        viewModel.getAccounts { (result: Result<Bool, NetworkingError>) in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertNotNil(AccountsStore.shared.accounts)
        XCTAssertTrue(AccountsStore.shared.accounts.count > 0)
        XCTAssertNotNil(AccountsStore.shared.currentAccount)
        XCTAssertNotNil(AccountsStore.shared.currentIndex)
        
        let yesterday = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 7, hour: 23, minute: 59, second: 59)) // current date as per mock
        let today = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 7, hour: 23, minute: 59, second: 59)) // current date as per mock
        let tomorrow = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 8, hour: 23, minute: 59, second: 59))
        let dayAfterTomorrow = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 9, hour: 23, minute: 59, second: 59))
        let threeDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 10, hour: 23, minute: 59, second: 59))
        let fourDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 11, hour: 23, minute: 59, second: 59))
        let fiveDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 12, hour: 23, minute: 59, second: 59))
        XCTAssertFalse(viewModel.isValidDate(yesterday!))
        XCTAssertFalse(viewModel.isValidDate(today!))
        XCTAssertFalse(viewModel.isValidDate(tomorrow!))
        XCTAssertFalse(viewModel.isValidDate(dayAfterTomorrow!))
        XCTAssertFalse(viewModel.isValidDate(threeDayAfter!)) // sunday
        XCTAssertTrue(viewModel.isValidDate(fourDayAfter!))
        XCTAssertTrue(viewModel.isValidDate(fiveDayAfter!))
    }
}
