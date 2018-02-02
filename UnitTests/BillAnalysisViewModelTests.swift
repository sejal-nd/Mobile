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
    
    override func setUp() {
        viewModel = BillAnalysisViewModel(usageService: MockUsageService())
    }
    
//    // Example accountDetail for an account with Bill Comparison
//    viewModel.currentBillComparison.value = BillComparison.from([
//        "meterUnit": "KWH",
//        "currencySymbol": "$",
//        "temperatureUnit": "FAHRENHEIT",
//        "reference": [
//            "charges": 100,
//            "usage": 100,
//            "startDate": "2017-08-13",
//            "endDate": "2017-09-13"
//        ],
//        "compared": [
//            "charges": 100,
//            "usage": 100,
//            "startDate": "2017-08-13",
//            "endDate": "2017-09-13"
//        ]
//    ])
    
    func testShouldShowElectricGasToggle() {
        if Environment.sharedInstance.opco == .comEd {
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for ComEd")
            }
        } else {
            viewModel.accountDetail = AccountDetail.from(["accountNumber": "0123456789", "serviceType": "GAS", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = GAS")
            }
            
            viewModel.accountDetail = AccountDetail.from(["accountNumber": "0123456789", "serviceType": "ELECTRIC", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = ELECTRIC")
            }
            
            viewModel.accountDetail = AccountDetail.from(["accountNumber": "0123456789", "serviceType": "GAS/ELECTRIC", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            if !viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should be displayed for serviceType = GAS/ELECTRIC")
            }
        }
        
    }
    
    func testShouldShowCurrentChargesSection() {
        if Environment.sharedInstance.opco == .comEd { // Only ComEd
            viewModel.accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            if viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should not be displayed if deliveryCharges, supplyCharges, and taxesAndFees are not provided or total 0")
            }
            
            viewModel.accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["deliveryCharges": 1], "SERInfo": [:]])!
            if !viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should be displayed if deliveryCharges, supplyCharges, and taxesAndFees total more than 0")
            }
            
        } else {
            if viewModel.shouldShowCurrentChargesSection {
                XCTFail("Current charges should not be displayed for opcos other than ComEd")
            }
        }
    }

}
