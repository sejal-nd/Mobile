//
//  MoveServiceConfirmationViewModelTests.swift
//  UnitTests
//
//  Created by RAMAITHANI on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class MoveServiceConfirmationViewModelTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBillingDescription() throws {
        
        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .default)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingDescription(), "The bill for service at your previous address will be delivered to", "Wrong billing description")
    }
    
    func testStopServiceAddress() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .default)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getStopServiceAddress(), "22 Cedarcone Ct, Baltimore, Maryland 21236", "Wrong stop service address")
    }
    
    func testStartServiceAddress() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .default)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getStartServiceAddress(), "7432 HINDON CIR *CONDO 202, Baltimore, Maryland 21236", "Wrong start service address")
    }

    func testBillingAddressResolved() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .moveResolved)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingAddress(), "Your new service address", "Wrong billing address resolved")
    }
    
    func testBillingAddressResolvedEbill() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .moveResolvedEbill)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingAddress(), "6983357223@example.com", "Wrong billing address resolved")
    }
    
    func testBillingAddressUnresolved() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .moveResolved)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingAddress(), "Your new service address", "Wrong billing address resolved")
    }
    
    func testBillingAddressUnresolvedEbill() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .moveUnresolvedEbill)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingAddress(), "6983357223@example.com", "Wrong Ebill Unresolved")
    }
    
    func testBillingAddressUnresolvedChangedAddress() throws {

        let response: MoveServiceResponse = MockModel.getModel(mockDataFileName: "MoveServiceConfirmationMock", mockUser: .moveUnresolvedChangeBillingAddress)
        let viewModel = MoveServiceConfirmationViewModel(moveServiceResponse: response)
        XCTAssertEqual(viewModel.getBillingAddress(), "6801 Rapid-Water Way *Apt 203, BALTIMORE, Maryland 21060", "Wrong unresolved changed billing address")
    }
}
