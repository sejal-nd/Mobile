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
        let viewModel = NewServiceAddressViewModel()

        viewModel.zipCode = "21201"

        XCTAssertTrue(viewModel.isZipValid)

        viewModel.zipCode = ""

        XCTAssertFalse(viewModel.isZipValid)
    }
    func testZipValidatedValidation() throws {
        let viewModel = NewServiceAddressViewModel()
        viewModel.zipCode = "21201"
        viewModel.validatedZipCodeResponse.accept(ValidatedZipCodeResponse(isValidZipCode: true))

        XCTAssertTrue(viewModel.isZipValidated)

        viewModel.validatedZipCodeResponse.accept(ValidatedZipCodeResponse(isValidZipCode: false))

        XCTAssertFalse(viewModel.isZipValidated)
    }

    func testStreetAddressValidation() throws {
        let viewModel = NewServiceAddressViewModel()

        viewModel.streetAddress = "910 PENNSYLVANIA AVE"

        XCTAssertTrue(viewModel.isStreetAddressValid)

        viewModel.streetAddress = ""

        XCTAssertFalse(viewModel.isStreetAddressValid)
    }
    func testPremiseIDValidation() throws {
        let viewModel = NewServiceAddressViewModel()

        viewModel.premiseID = "819708302"

        XCTAssertTrue(viewModel.isValidPremiseID)

        viewModel.premiseID = ""

        XCTAssertFalse(viewModel.isValidPremiseID)
    }
    func testCanContinueValidation() throws {
        let viewModel = NewServiceAddressViewModel()
        viewModel.zipCode = "21201"
        viewModel.validatedZipCodeResponse.accept(ValidatedZipCodeResponse(isValidZipCode: true))

        viewModel.streetAddress = "910 PENNSYLVANIA AVE"
        viewModel.premiseID = "819708302"

        XCTAssertTrue(viewModel.canEnableContinue)

        viewModel.premiseID = ""

        XCTAssertFalse(viewModel.canEnableContinue)
    }
}
