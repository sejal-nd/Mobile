//
//  BillAnalysisViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 10/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class BillAnalysisViewModelTests: XCTestCase {
    
    var viewModel: BillAnalysisViewModel!
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        viewModel = BillAnalysisViewModel(usageService: MockUsageService())
    }
    
    func testShouldShowElectricGasToggle() {
        if Environment.sharedInstance.opco == .comEd {
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for ComEd")
            }
        } else {
            viewModel.accountDetail = AccountDetail(serviceType: "GAS")
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = GAS")
            }
            
            viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = ELECTRIC")
            }
            
            viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
            if !viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should be displayed for serviceType = GAS/ELECTRIC")
            }
        }
        
    }
    
    func testShouldShowCurrentChargesSection() {
        if Environment.sharedInstance.opco == .comEd { // Only ComEd
            viewModel.accountDetail = AccountDetail()
            if viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should not be displayed if deliveryCharges, supplyCharges, and taxesAndFees are not provided or total 0")
            }
            
            viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(deliveryCharges: 1))
            if !viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should be displayed if deliveryCharges, supplyCharges, and taxesAndFees total more than 0")
            }
            
        } else {
            if viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should not be displayed for opcos other than ComEd")
            }
        }
    }
    
    func testNoDataBarDateLabelText() {
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(endDate: "2017-08-01"))
        
        // Default is Previous Bill
        viewModel.noDataBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "JUL 01", "Expected \"JUL 01\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
        
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0 // Last Year
        viewModel.noDataBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "2016", "Expected \"2016\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
    }
    
    func testPreviousBarHeightConstraintValue() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(charges: -10))
        
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 3, "Expected 3 because compared charges < 0, got \(val) instead")
        }).disposed(by: disposeBag)
        
        // If we have a projection:
        // Test case: Compared charges are the highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 180), compared: UsageBillPeriod(charges: 200))
        viewModel.electricForecast.value = BillForecast(projectedCost: 150)
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 134, "Expected 134, got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Projected charges are the highest
        viewModel.electricForecast.value = BillForecast(projectedCost: 210)
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 210))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Reference charges are the highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 220))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // No projections
        // Test case: Reference charges are greater than compared charges
        viewModel.electricForecast.value = nil
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 220))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Compared charges are greater than reference charges
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220))
        viewModel.previousBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 134, "Expected 134, got \(val) instead")
        }).disposed(by: disposeBag)
    }
    
    func testPreviousBarDollarLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")

        viewModel.currentBillComparison.value = BillComparison(compared: UsageBillPeriod(charges: 220))
        viewModel.previousBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "$220.00", "Expected $220.00, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
    }
    
    func testPreviousBarDateLabelText() {
        viewModel.currentBillComparison.value = BillComparison(compared: UsageBillPeriod(endDate: "2017-08-01"))
        
        // Default is Previous Bill
        viewModel.previousBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "AUG 01", "Expected \"JUL 01\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
        
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0 // Last Year
        viewModel.previousBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "2017", "Expected \"2017\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
    }

}
