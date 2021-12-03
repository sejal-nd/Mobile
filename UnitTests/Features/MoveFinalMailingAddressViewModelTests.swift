//
//  MoveFinalMailingAddressViewModelTests.swift
//  UnitTests
//
//  Created by Mithlesh Kumar on 27/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class MoveFinalMailingAddressViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStreetAddressValidation() throws {

        let viewModel = MoveFinalMailingAddressViewModel()

        viewModel.streetAddress = "1257 Sargeant St"
        
        XCTAssertTrue(viewModel.isStreetAddressValid)
        XCTAssertEqual(viewModel.streetAddress, "1257 Sargeant St")

        viewModel.streetAddress = ""

        XCTAssertFalse(viewModel.isStreetAddressValid)
    }
    func testZipValidation() throws {

        let viewModel = MoveFinalMailingAddressViewModel()

        viewModel.zipCode = "21223"

        XCTAssertTrue(viewModel.isZipValid)
        XCTAssertEqual(viewModel.zipCode, "21223")

        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.isZipValid)
    }
    func testCityValidation() throws {

        let viewModel = MoveFinalMailingAddressViewModel()

        viewModel.city = "Baltimore"
        XCTAssertTrue(viewModel.isCityValid)
        XCTAssertEqual(viewModel.city, "Baltimore")

        viewModel.city = ""

        XCTAssertFalse(viewModel.isCityValid)
    }

    func testContinueValidation() throws {
        let viewModel = MoveFinalMailingAddressViewModel()

        viewModel.streetAddress = "1257 Sargeant St"
        viewModel.zipCode = "21223"
        viewModel.city    = "Baltimore"
        viewModel.state = USState.AL
        viewModel.stateSelectedIndex = 1

        XCTAssertTrue(viewModel.canEnableContinue)

    
        viewModel.streetAddress = ""
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "1257 Sargeant St"
        viewModel.zipCode = ""
        viewModel.city    = "Baltimore"
        viewModel.state = USState.AL
        viewModel.stateSelectedIndex = 1
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "1257 Sargeant St"
        viewModel.zipCode = "21223"
        viewModel.city    = ""
        viewModel.state = USState.AL
        viewModel.stateSelectedIndex = 1
        XCTAssertFalse(viewModel.canEnableContinue)


        viewModel.stateSelectedIndex = 0
        XCTAssertFalse(viewModel.canEnableContinue)
        
    }

}
