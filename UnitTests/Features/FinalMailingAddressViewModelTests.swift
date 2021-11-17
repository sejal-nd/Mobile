//
//  FinalMailingAddressViewModelTests.swift
//  UnitTests
//
//  Created by RAMAITHANI on 27/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class FinalMailingAddressViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStreetAddress() throws {
        
        let viewModel = FinalMailingAddressViewModel()
        
        viewModel.streetAddress = ""
        XCTAssertFalse(viewModel.isStreetAddressValid)
        
        viewModel.streetAddress = "123 Street"
        XCTAssertTrue(viewModel.isStreetAddressValid)
    }
    
    func testCity() throws {
        
        let viewModel = FinalMailingAddressViewModel()
        
        viewModel.city = ""
        XCTAssertFalse(viewModel.isCityValid)
        
        viewModel.city = "123 City"
        XCTAssertTrue(viewModel.isCityValid)
    }
    
    func testZipCode() throws {
        
        let viewModel = FinalMailingAddressViewModel()
        
        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.isZipValid)
        
        viewModel.zipCode = "1"
        XCTAssertFalse(viewModel.isZipValid)

        viewModel.zipCode = "123"
        XCTAssertFalse(viewModel.isZipValid)

        viewModel.zipCode = "12345"
        XCTAssertTrue(viewModel.isZipValid)

        viewModel.zipCode = "123456789"
        XCTAssertFalse(viewModel.isZipValid)
    }
    
    func testContinueButtonEnable() throws {
        
        let viewModel = FinalMailingAddressViewModel()
        
        viewModel.streetAddress = ""
        viewModel.city = ""
        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "123 Street"
        viewModel.city = ""
        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = ""
        viewModel.city = "123 City"
        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = ""
        viewModel.city = ""
        viewModel.zipCode = "12345"
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "123 Street"
        viewModel.city = "123 City"
        viewModel.zipCode = ""
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "123 Street"
        viewModel.city = ""
        viewModel.zipCode = "12345"
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "123 Street"
        viewModel.city = "123 City"
        viewModel.zipCode = "12345"
        viewModel.stateSelectedIndex = 0
        XCTAssertFalse(viewModel.canEnableContinue)

        viewModel.streetAddress = "123 Street"
        viewModel.city = "123 City"
        viewModel.zipCode = "12345"
        viewModel.stateSelectedIndex = 1
        XCTAssertTrue(viewModel.canEnableContinue)
    }
}
