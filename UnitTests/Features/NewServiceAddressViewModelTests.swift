//
//  NewServiceAddressViewModelTests.swift
//  UnitTests
//
//  Created by Mithlesh Kumar on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class NewServiceAddressViewModelTests: XCTestCase {

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

    func testZipValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = NewServiceAddressViewModel(moveServiceFlowData:moveServiceFlow)

        viewModel.zipCode = "21201"
        XCTAssertTrue(viewModel.isZipValid)
        XCTAssertEqual(viewModel.zipCode, "21201")


        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.isZipValid)
    }

    func testZipValidatedValidation() throws {
        KeychainController.default.set("default", forKey: .tokenKeychainKey)

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = NewServiceAddressViewModel(moveServiceFlowData: moveServiceFlow)
        viewModel.zipCode = "21201"

        XCTAssertTrue(viewModel.isZipValid)

        let expectation = expectation(description: "API Response Expectation")
        viewModel.validateZipCode { _ in
            expectation.fulfill()
        } onFailure: { error in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 120, handler: nil)
        
        XCTAssertTrue(viewModel.isZipValidated)
    }

    func testStreetAddressValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = NewServiceAddressViewModel(moveServiceFlowData:moveServiceFlow)

        viewModel.streetAddress = "910 PENNSYLVANIA AVE"

        XCTAssertTrue(viewModel.isStreetAddressValid)
        XCTAssertEqual(viewModel.streetAddress, "910 PENNSYLVANIA AVE")

        viewModel.streetAddress = ""
        XCTAssertFalse(viewModel.isStreetAddressValid)
    }

    func testPremiseIDValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = NewServiceAddressViewModel(moveServiceFlowData:moveServiceFlow)

        viewModel.premiseID = "819708302"
        XCTAssertTrue(viewModel.isValidPremiseID)
        XCTAssertEqual(viewModel.premiseID, "819708302")

        viewModel.premiseID = ""
        XCTAssertFalse(viewModel.isValidPremiseID)
    }

    func testCanContinueValidation() throws {

        let accounts: [Account] = MockModel.getModel(mockDataFileName: "AccountsMock", mockUser: .default)

        let currentAccount = accounts.first
        let currentAccountDetails: AccountDetail = MockModel.getModel(mockDataFileName: "AccountDetailsMock", mockUser: .default)
        let workDays: WorkdaysResponse =  MockModel.getModel(mockDataFileName: "WorkdaysMock", mockUser: .default)

        let moveServiceFlow = MoveServiceFlowData(workDays: workDays.list, stopServiceDate: Date.now, currentPremise:currentAccount!.currentPremise!, currentAccount:currentAccount!, currentAccountDetail: currentAccountDetails, verificationDetail: nil, hasCurrentServiceAddressForBill: false)

        let viewModel = NewServiceAddressViewModel(moveServiceFlowData:moveServiceFlow)

        viewModel.zipCode = "21201"
        viewModel.validatedZipCodeResponse.accept(ValidatedZipCodeResponse(isValidZipCode: true))

        viewModel.streetAddress = "910 PENNSYLVANIA AVE"
        viewModel.premiseID = "4798590000"


        let expectation = expectation(description: "API Response Expectation")
        viewModel.lookupAddress { _ in
            expectation.fulfill()
        } onFailure: { error in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 120, handler: nil)

        XCTAssertTrue(viewModel.canEnableContinue)
    }
}
