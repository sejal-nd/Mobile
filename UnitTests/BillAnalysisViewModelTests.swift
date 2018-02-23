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
    
    // MARK: No Data Bar Drivers
    
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
    
    // MARK: Previous Bar Drivers
    
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
    
    // MARK: Current Bar Drivers
    
    func testCurrentBarHeightConstraintValue() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: -10), compared: UsageBillPeriod())
        
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 3, "Expected 3 because reference charges < 0, got \(val) instead")
        }).disposed(by: disposeBag)
        
        // If we have a projection:
        // Test case: Reference charges are the highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 180))
        viewModel.electricForecast.value = BillForecast(projectedCost: 150)
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 134, "Expected 134, got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Projected charges are the highest
        viewModel.electricForecast.value = BillForecast(projectedCost: 210)
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 210))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Compared charges are the highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 220))
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 220))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // No projections
        // Test case: Compared charges are greater than compared charges
        viewModel.electricForecast.value = nil
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (200 / 220))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val) instead")
        }).disposed(by: disposeBag)
        
        // Test case: Reference charges are greater than reference charges
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 220), compared: UsageBillPeriod(charges: 200))
        viewModel.currentBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 134, "Expected 134, got \(val) instead")
        }).disposed(by: disposeBag)
    }
    
    func testCurrentBarDollarLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 220))
        viewModel.currentBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "$220.00", "Expected $220.00, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
    }
    
    func testCurrentBarDateLabelText() {
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(endDate: "2017-08-01"))
        
        // Default is Previous Bill
        viewModel.currentBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "AUG 01", "Expected \"JUL 01\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
        
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0 // Last Year
        viewModel.currentBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "2017", "Expected \"2017\", got \"\(text ?? "nil")\"")
        }).disposed(by: disposeBag)
    }
    
    // MARK: Projection Bar Drivers
    
    func testProjectedCost() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(projectedCost: 210)
        viewModel.gasForecast.value = BillForecast(projectedCost: 182)

        viewModel.projectedCost.asObservable().take(1).subscribe(onNext: { cost in
            if let expectedVal = cost {
                XCTAssert(expectedVal == 210, "Expected 210, got \(expectedVal)")
            } else {
                XCTFail("Unexpected nil")
            }
        }).disposed(by: disposeBag)
        
        if Environment.sharedInstance.opco != .comEd { // ComEd is electric only
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedCost.asObservable().take(1).subscribe(onNext: { cost in
                if let expectedVal = cost {
                    XCTAssert(expectedVal == 182, "Expected 182, got \(expectedVal)")
                } else {
                    XCTFail("Unexpected nil")
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func testProjectedUsage() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(projectedUsage: 210)
        viewModel.gasForecast.value = BillForecast(projectedUsage: 182)
        
        viewModel.projectedUsage.asObservable().take(1).subscribe(onNext: { cost in
            if let expectedVal = cost {
                XCTAssert(expectedVal == 210, "Expected 210, got \(expectedVal)")
            } else {
                XCTFail("Unexpected nil")
            }
        }).disposed(by: disposeBag)
        
        if Environment.sharedInstance.opco != .comEd { // ComEd is electric only
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedUsage.asObservable().take(1).subscribe(onNext: { cost in
                if let expectedVal = cost {
                    XCTAssert(expectedVal == 182, "Expected 182, got \(expectedVal)")
                } else {
                    XCTFail("Unexpected nil")
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func testShouldShowProjectedBar() {
        // Just testing the basic case for coverage. Quality testing will be performed on the functions that this driver combines
        viewModel.shouldShowProjectedBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectedBar should be false initially")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarHeightConstraintValue() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        
        // Test case: No projection
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 0, "Expected 0 initially")
        }).disposed(by: disposeBag)
        
        // Test case: Projected cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 182))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssert(val == 134, "Expected 134, got \(val)")
        }).disposed(by: disposeBag)
        
        // Test case: Reference cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 230), compared: UsageBillPeriod(charges: 182))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (220 / 230))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val)")
        }).disposed(by: disposeBag)
        
        // Test case: Compared cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 230), compared: UsageBillPeriod(charges: 240))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (220 / 240))
            XCTAssert(val == expectedVal, "Expected \(expectedVal), got \(val)")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarDollarLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.electricForecast.value = BillForecast(projectedUsage: 500, projectedCost: 220)
        
        // Test case: Account not modeled for OPower - show usage
        viewModel.projectedBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "500 kWh", "Expected 500 kWh, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
        
        // Test case: Account IS modeled for OPower, show cost
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC", isModeledForOpower: true)
        viewModel.projectedBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "$220.00", "Expected $220.00, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarDateLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(billingEndDate: "2019-08-13")
        viewModel.gasForecast.value = BillForecast(billingEndDate: "2019-07-03")
        
        // Test case: Electric
        viewModel.projectedBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "AUG 13", "Expected AUG 13, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
        
        if Environment.sharedInstance.opco != .comEd { // ComEd is electric only
            // Test case: Gas
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssert(text == "JUL 03", "Expected JUL 03, got \(text ?? "nil")")
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Projection Not Available Bar Drivers
    
    func testShouldShowProjectionNotAvailableBar() {
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when projectedCost is nil")
        }).disposed(by: disposeBag)
        
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let twoWeeksOut = Calendar.current.date(byAdding: .weekOfMonth, value: 2, to: today)!
        
        // Test case: Electric forecast with less than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: tomorrow))
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "shouldShowProjectionNotAvailableBar should be true when less than 7 days from billingStartDate")
        }).disposed(by: disposeBag)
        
        // Test case: Electric forecast with greater than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut))
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when more than 7 days from billingStartDate")
        }).disposed(by: disposeBag)
        
        if Environment.sharedInstance.opco != .comEd { // ComEd is electric only
            // Test case: Gas forecast with less than 7 days since start
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: tomorrow))
            viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
                XCTAssert(shouldShow, "shouldShowProjectionNotAvailableBar should be true when less than 7 days from billingStartDate")
            }).disposed(by: disposeBag)

            // Test case: Gas forecast with greater than 7 days since start
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut))
            viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
                XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when more than 7 days from billingStartDate")
            }).disposed(by: disposeBag)
        }
    }
    
    func testProjectionNotAvailableDaysRemainingText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let sixDaysOut = Calendar.current.date(byAdding: .day, value: 6, to: today)!
        let threeDaysOut = Calendar.current.date(byAdding: .day, value: 3, to: today)!
        
        // Test case: Electric forecast with less than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut))
        viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "1 day", "Expected 1 day, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
        
        // Test case: Electric forecast with greater than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut))
        viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssert(text == "4 days", "Expected 4 days, got \(text ?? "nil")")
        }).disposed(by: disposeBag)
        
        if Environment.sharedInstance.opco != .comEd { // ComEd is electric only
            // Test case: Gas forecast with less than 7 days since start
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut))
            viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssert(text == "1 day", "Expected 1 day, got \(text ?? "nil")")
            }).disposed(by: disposeBag)
            
            // Test case: Gas forecast with greater than 7 days since start
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut))
            viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssert(text == "4 days", "Expected 4 days, got \(text ?? "nil")")
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Bar Description Box Drivers
    
    func testBarDescriptionDateLabelText() {
        
    }

}
