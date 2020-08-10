//
//  Top5EnergyTipsTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class Top5EnergyTipsTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    func testSuccessCutoff() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: .default)
        
        let expectedValues: [EnergyTip] = try! MockJSONManager.shared.mappableArray(fromFile: .energyTips, key: .default)
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(Array(observer.events.dropLast()), [expectedValues])
    }
    
    func testSuccessLessThan5() {
        MockUser.current = MockUser(globalKeys: .energyTips3)
        MockAccountService.loadAccountsSync()
        
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: .default)
        
        let expectedValues: [EnergyTip] = try! MockJSONManager.shared.mappableArray(fromFile: .energyTips, key: .energyTips3)
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(Array(observer.events.dropLast()), [expectedValues])
    }
    
    func testFailure() {
        MockUser.current = MockUser(globalKeys: .error)
        MockAccountService.loadAccountsSync()
        
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: .default)
        
        let expectedValues = ["fetch failed"]
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!zip(observer.events, expectedValues)
            .map { ($0.0.value.error as? ServiceError).serviceMessage == $0.1 }
            .contains(false))
    }
}
