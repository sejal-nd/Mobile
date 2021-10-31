//
//  ReviewMoveServiceViewModelTest.swift
//  UnitTests
//
//  Created by Mithlesh Kumar on 27/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class ReviewMoveServiceViewModelTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidDateAMIUser() throws {

        let viewModel = ReviewMoveServiceViewModel()

        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)


        let today = DateFormatter.mmDdYyyyFormatter.date(from: "10/07/2021")
        let yesterday = DateFormatter.mmDdYyyyFormatter.date(from: "10/06/2021")
        let tomorrow = DateFormatter.mmDdYyyyFormatter.date(from: "10/08/2021")
        let dayAfterTomorrow = DateFormatter.mmDdYyyyFormatter.date(from: "10/09/2021")
        
        XCTAssertFalse(viewModel.isValidDate(yesterday!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertTrue(viewModel.isValidDate(today!,workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertTrue(viewModel.isValidDate(tomorrow!,workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertTrue(viewModel.isValidDate(dayAfterTomorrow!,workDays: workDays.list, accountDetails:currentAccountDetails))
    }

    func testValidDateNonAMIUser() throws {

        let viewModel = ReviewMoveServiceViewModel()

        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)


        let yesterday = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 7, hour: 23, minute: 59, second: 59)) // current date as per mock
        let today = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 7, hour: 23, minute: 59, second: 59)) // current date as per mock
        let tomorrow = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 8, hour: 23, minute: 59, second: 59))
        let dayAfterTomorrow = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 9, hour: 23, minute: 59, second: 59))
        let threeDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 10, hour: 23, minute: 59, second: 59))
        let fourDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 11, hour: 23, minute: 59, second: 59))
        let fiveDayAfter = Calendar.opCo.date(from: DateComponents(year: 2021, month: 10, day: 12, hour: 23, minute: 59, second: 59))

        XCTAssertFalse(viewModel.isValidDate(yesterday!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertFalse(viewModel.isValidDate(today!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertFalse(viewModel.isValidDate(tomorrow!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertFalse(viewModel.isValidDate(dayAfterTomorrow!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertFalse(viewModel.isValidDate(threeDayAfter!, workDays: workDays.list, accountDetails: currentAccountDetails))
        XCTAssertTrue(viewModel.isValidDate(fourDayAfter!, workDays: workDays.list, accountDetails: currentAccountDetails)) // sunday
        XCTAssertTrue(viewModel.isValidDate(fiveDayAfter!, workDays: workDays.list, accountDetails: currentAccountDetails))
    }

}
