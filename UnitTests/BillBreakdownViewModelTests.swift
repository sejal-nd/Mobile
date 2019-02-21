//
//  BillBreakdownViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 10/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class BillBreakdownViewModelTests: XCTestCase {
    
    let viewModel = BillBreakdownViewModel(accountDetail: .fromMockJson(forKey: .billBreakdown))
    
    func testSupplyCharges() {
        XCTAssertEqual(viewModel.supplyCharges, 42)
    }
    
    func testTaxesAndFees() {
        XCTAssertEqual(viewModel.taxesAndFees, 13)
    }
    
    func testDeliveryCharges() {
        XCTAssertEqual(viewModel.deliveryCharges, 38)
    }
    
    func testSupplyChargesString() {
        XCTAssertEqual(viewModel.supplyChargesString, "$42.00")
    }
    
    func testTaxesAndFeesString() {
        XCTAssertEqual(viewModel.taxesAndFeesString, "$13.00")
    }
    
    func testDeliveryChargesString() {
        XCTAssertEqual(viewModel.deliveryChargesString, "$38.00")
    }
    
    func testTotalChargesString() {
        XCTAssertEqual(viewModel.totalChargesString, "$93.00")
    }
    
    

}
