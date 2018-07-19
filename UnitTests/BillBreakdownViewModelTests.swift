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
    
    func createViewModel(supplyCharges: Double? = nil,
                         taxesAndFees: Double? = nil,
                         deliveryCharges: Double? = nil) -> BillBreakdownViewModel {
        return BillBreakdownViewModel(accountDetail: AccountDetail(billingInfo: BillingInfo(deliveryCharges: deliveryCharges,
                                                                                            supplyCharges: supplyCharges,
                                                                                            taxesAndFees: taxesAndFees)))
    }
    
    func testSupplyCharges() {
        let viewModel = createViewModel(supplyCharges: 5.1)
        XCTAssertEqual(viewModel.supplyCharges, 5.1)
    }
    
    func testTaxesAndFees() {
        let viewModel = createViewModel(taxesAndFees: 6.4)
        XCTAssertEqual(viewModel.taxesAndFees, 6.4)
    }
    
    func testDeliveryCharges() {
        let viewModel = createViewModel(deliveryCharges: 75.2)
        XCTAssertEqual(viewModel.deliveryCharges, 75.2)
    }
    
    func testSupplyChargesString() {
        let viewModel = createViewModel(supplyCharges: 5.1)
        XCTAssertEqual(viewModel.supplyChargesString, "$5.10")
    }
    
    func testTaxesAndFeesString() {
        let viewModel = createViewModel(taxesAndFees: 6.4)
        XCTAssertEqual(viewModel.taxesAndFeesString, "$6.40")
    }
    
    func testDeliveryChargesString() {
        let viewModel = createViewModel(deliveryCharges: 75.2)
        XCTAssertEqual(viewModel.deliveryChargesString, "$75.20")
    }
    
    func testTotalChargesString() {
        let viewModel = createViewModel(supplyCharges: 5.1, taxesAndFees: 6.43, deliveryCharges: 75.2)
        XCTAssertEqual(viewModel.totalChargesString, "$86.73")
    }
    
    

}
