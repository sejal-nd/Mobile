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
        viewModel = BillAnalysisViewModel(usageService: ServiceFactory.createUsageService())
    }
    
    func testPreviousBarHeightConstraintValue() {
        viewModel.currentBillComparison.value = BillComparison.from(["meterUnit": "KWH",
                                                                     "currencySymbol": "$",
                                                                     "temperatureUnit": "FAHRENHEIT",
                                                                     "reference": [
                                                                        "charges": 100,
                                                                        "usage": 100,
                                                                        "startDate": "2017-08-13",
                                                                        "endDate": "2017-09-13"
                                                                     ],
                                                                     "compared": [
                                                                        "charges": 100,
                                                                        "usage": 100,
                                                                        "startDate": "2017-08-13",
                                                                        "endDate": "2017-09-13"
                                                                     ]])
        
        
    }

}
