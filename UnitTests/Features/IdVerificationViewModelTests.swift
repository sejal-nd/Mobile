//
//  IdVerificationViewModelTests.swift
//  UnitTests
//
//  Created by Mithlesh Kumar on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class IdVerificationViewModelTests: XCTestCase {

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

    func testSSNValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = IdVerificationViewModel(moveDataFlow: moveServiceFlow)
        let idVerification = IdVerification(ssn: "123456789", dateOfBirth: nil, employmentStatus: nil)

        viewModel.idVerification = idVerification

        XCTAssertTrue(viewModel.isValidSSN(ssn: "123456789"))
        XCTAssertEqual(viewModel.idVerification.ssn, "123456789")

        XCTAssertFalse(viewModel.isValidSSN(ssn: "123456"))
        XCTAssertFalse(viewModel.isValidSSN(ssn: "1234567891234"))
    }

    func testAgeValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = IdVerificationViewModel(moveDataFlow: moveServiceFlow)

        let age18Plus = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        XCTAssertTrue(viewModel.validateAge(selectedDate: age18Plus))

        let ageNon18Plus = Date()
        XCTAssertFalse(viewModel.validateAge(selectedDate: ageNon18Plus))
    }
    func testFullValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = IdVerificationViewModel(moveDataFlow: moveServiceFlow)

        let age18Plus = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        let idVerification = IdVerification(ssn: "123456789", dateOfBirth: age18Plus, employmentStatus: ("Retired", 5))

        viewModel.idVerification = idVerification
        XCTAssertTrue(viewModel.validation())

        viewModel.idVerification.ssn = "1234567891234"
        XCTAssertFalse(viewModel.validation())
    }
    
    func testDrivingLicenseValidation() throws {

        let licenseNumber = "12345678901234"
        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = IdVerificationViewModel(moveDataFlow: moveServiceFlow)
        viewModel.idVerification = IdVerification(ssn: nil, dateOfBirth: nil, employmentStatus: nil, driverLicenseNumber: licenseNumber, stateOfIssueDriverLincense: nil)

        XCTAssertTrue(viewModel.isValidDrivingLicense(drivingLicense: licenseNumber, inputString: licenseNumber))
        XCTAssertEqual(viewModel.idVerification.driverLicenseNumber, licenseNumber)

        XCTAssertFalse(viewModel.isValidDrivingLicense(drivingLicense: "1234567890123456", inputString:"1234567890123456"))
    }

}
