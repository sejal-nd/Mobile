//
//  MoveStartServiceViewModelTests.swift
//  UnitTests
//
//  Created by Mithlesh Kumar on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class MoveStartServiceViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testValidDateAMIUser() throws {
        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = MoveStartServiceViewModel(moveServiceFlowData: moveServiceFlow)
    
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
        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .nonAMIUser)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .nonAMIUser)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .nonAMIUser)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = MoveStartServiceViewModel(moveServiceFlowData: moveServiceFlow)

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
        XCTAssertFalse(viewModel.isValidDate(threeDayAfter!))
        XCTAssertTrue(viewModel.isValidDate(fourDayAfter!)) // sunday
        XCTAssertTrue(viewModel.isValidDate(fiveDayAfter!))
    }

}


