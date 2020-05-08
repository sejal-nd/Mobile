//
//  SERPTSViewModelTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/23/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class SERPTSViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    func testShouldShowSmartEnergyRewards() {
        var viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [])
        XCTAssert(!viewModel.shouldShowSmartEnergyRewards)
        
        viewModel = SERPTSViewModel(accountService: MockAccountService(),
                                                  accountDetail: .fromMockJson(forKey: .pts),
                                                  eventResults: [])
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards, Environment.shared.opco != .peco)
        
        viewModel = SERPTSViewModel(accountService: MockAccountService(),
                                                  accountDetail: .fromMockJson(forKey: .serEnrolled),
                                                  eventResults: [])
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards, Environment.shared.opco != .peco)
        
            viewModel = SERPTSViewModel(accountService: MockAccountService(),
                                                      accountDetail: .fromMockJson(forKey: .ptsAndSerEnrolled),
                                                      eventResults: [])
        XCTAssertEqual(viewModel.shouldShowSmartEnergyRewards, Environment.shared.opco != .peco)
    }
    
    func testShouldShowSmartEnergyRewardsContent() {
        var viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [])
        viewModel.shouldShowSmartEnergyRewardsContent.asObservable().single().subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow)
        }).disposed(by: disposeBag)
        
        viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [SERResult()])
        viewModel.shouldShowSmartEnergyRewardsContent.asObservable().single().subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow)
        }).disposed(by: disposeBag)
    }
    
    func testSmartEnergyRewardsSeasonLabelText() {
        var viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [])
        viewModel.smartEnergyRewardsSeasonLabelText.asObservable().single().subscribe(onNext: { text in
            XCTAssertNil(text)
        }).disposed(by: disposeBag)
        
        viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [SERResult(eventStart: DateFormatter.mmDdYyyyFormatter.date(from: "05/23/2018")!)])
        
        viewModel.smartEnergyRewardsSeasonLabelText.asObservable().single().subscribe(onNext: { text in
            XCTAssertEqual(text, "Summer 2018")
        }).disposed(by: disposeBag)
    }
    
    func testSmartEnergyRewardsFooterText() {
        var viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [SERResult()])
        viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
            XCTAssertEqual(text, "You earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use.")
        }).disposed(by: disposeBag)

        viewModel = SERPTSViewModel(accountService: MockAccountService(), accountDetail: .default, eventResults: [])
        switch Environment.shared.opco {
        case .comEd:
            viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
                XCTAssertEqual(text, "As a Peak Time Savings customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent Peak Time Savings season will display here once available.")
            }).disposed(by: disposeBag)
        case .bge, .peco:
            viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
                XCTAssertEqual(text, "As a Smart Energy Rewards customer, you can earn bill credits for every kWh you save. We calculate how much you save by comparing the energy you use on an Energy Savings Day to your typical use. Your savings information for the most recent Smart Energy Rewards season will display here once available.")
            }).disposed(by: disposeBag)
        case .pepco:
            viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
                XCTAssertEqual(text, "todo")
            }).disposed(by: disposeBag)
        case .ace:
            viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
                XCTAssertEqual(text, "todo")
            }).disposed(by: disposeBag)
        case .delmarva:
            viewModel.smartEnergyRewardsFooterText.asObservable().single().subscribe(onNext: { text in
                XCTAssertEqual(text, "todo")
            }).disposed(by: disposeBag)
        }
    }
}
