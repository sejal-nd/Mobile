//
//  SmartEnergyRewardsVCViewModelTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/23/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class SmartEnergyRewardsVCViewModelTests: XCTestCase {
    
    func testShouldShowSmartEnergyRewards() {
        var viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail())
        XCTAssert(!viewModel.shouldShowSmartEnergyRewards)
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(isPTSAccount: true))
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards,
                       Environment.shared.opco != .peco)
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(premiseInfo: [Premise(smartEnergyRewards: "ENROLLED")]))
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards,
                       Environment.shared.opco != .peco)
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(isPTSAccount: true,
                                                                premiseInfo: [Premise(smartEnergyRewards: "ENROLLED")]))
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards,
                       Environment.shared.opco != .peco)
        
    }
    
    func testShouldShowSmartEnergyRewardsContent() {
        var viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail())
        XCTAssert(!viewModel.shouldShowSmartEnergyRewardsContent)
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(serInfo: SERInfo(eventResults: [SERResult()])))
        XCTAssert(viewModel.shouldShowSmartEnergyRewardsContent)
    }
    
    func testSmartEnergyRewardsSeasonLabelText() {
        var viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail())
        XCTAssertNil(viewModel.smartEnergyRewardsSeasonLabelText)
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(serInfo: SERInfo(eventResults: [SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!)])))
        XCTAssertEqual(viewModel.smartEnergyRewardsSeasonLabelText, "Summer 2018")
    }
    
    func testSmartEnergyRewardsFooterText() {
        var viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail(serInfo: SERInfo(eventResults: [SERResult()])))
        XCTAssertEqual(viewModel.smartEnergyRewardsFooterText, "You earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.")
        
        viewModel = SmartEnergyRewardsVCViewModel(accountDetail: AccountDetail())
        switch Environment.shared.opco {
        case .comEd:
            XCTAssertEqual(viewModel.smartEnergyRewardsFooterText, "As a Peak Time Savings customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent Peak Time Savings season will display here once available.")
        case .bge, .peco:
            XCTAssertEqual(viewModel.smartEnergyRewardsFooterText, "As a Smart Energy Rewards customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent Smart Energy Rewards season will display here once available.")
        }
    }
}
