//
//  StopConfirmationScreenViewModelTests.swift
//  UnitTests
//
//  Created by RAMAITHANI on 27/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class StopConfirmationScreenViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testServiceDate() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .default)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getStopServiceDate(), "November 11, 2021, 8:00 a.m.", "Stop date is worng")
    }
    
    func testBillingAddressResolved() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopResolved)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getFinalBillAddress(), "The service address above", "Wrong billing address resolved")
    }
    
    func testBillingAddressResolvedEbill() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopResolvedEbill)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getFinalBillAddress(), "6958491198@example.com", "Wrong Ebill address resolved")
    }
    
    func testBillingAddressUnresolved() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopUnresolved)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getFinalBillAddress(), "Same as current service address", "Wrong billing address unresolved")
    }
    
    func testBillingAddressUnresolvedEbill() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopUnresolvedEbill)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getFinalBillAddress(), "6958491198@example.com", "Wrong Ebill Unresolved")
    }
    
    func testBillingAddressUnresolvedChangedAddress() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopUnresolvedChangedBillingAddress)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getFinalBillAddress(), "7432 Hindon Cir, Baltimore, Maryland 21244", "Wrong unresolved changed billing address")
    }

    func testStopServiceAddress() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .default)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getStopServiceAddress(), "6801 Rapid-Water Way *Apt 203, Glen Burnie, Maryland 21060", "")
    }

    func testNextStepDescriptionResolved() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopResolved)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getNextStepDescription(), "We will disconnect your service remotely through your smart meter. You will not need to be present. Please prepare for your service to be shut off as early as 8 a.m.", "Wrong next step description for resolved")
    }
    
    func testNextStepDescriptionUnresolved() throws {

        let response: StopServiceResponse = MockModel.getModel(mockDataFileName: "StopServiceConfirmationMock", mockUser: .stopUnresolved)
        let viewModel = StopConfirmationScreenViewModel(stopServiceResponse: response)
        XCTAssertEqual(viewModel.getNextStepDescription(), "We are currently processing your request. If we need more information to complete your request, we will contact you within 24-48 business hours.", "Wrong next step description for unresolved")
    }
}
