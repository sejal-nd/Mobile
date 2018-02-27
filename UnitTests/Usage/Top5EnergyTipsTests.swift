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
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: AccountDetail(accountNumber: "8", premiseNumber: ""))
        
        let expectedValues = [[
            EnergyTip(title: "title 1", body: "body 1"),
            EnergyTip(title: "title 2", body: "body 2"),
            EnergyTip(title: "title 3", body: "body 3"),
            EnergyTip(title: "title 4", body: "body 4"),
            EnergyTip(title: "title 5", body: "body 5")
            ]]
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events[0].value.element!.count, expectedValues[0].count)
        XCTAssert(!zip(observer.events, expectedValues)
            .map { $0.0.value.element! == $0.1 }
            .contains(false))
    }
    
    func testSuccessLessThan5() {
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: AccountDetail(accountNumber: "3", premiseNumber: ""))
        
        let expectedValues = [[
            EnergyTip(title: "title 1", body: "body 1"),
            EnergyTip(title: "title 2", body: "body 2"),
            EnergyTip(title: "title 3", body: "body 3")
            ]]
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events[0].value.element!.count, expectedValues[0].count)
        XCTAssert(!zip(observer.events, expectedValues)
            .map { $0.0.value.element! == $0.1 }
            .contains(false))
    }
    
    func testFailure() {
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: AccountDetail(accountNumber: "", premiseNumber: ""))
        
        let expectedValues = ["fetch failed"]
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!zip(observer.events, expectedValues)
            .map { ($0.0.value.error as! ServiceError).serviceMessage == $0.1 }
            .contains(false))
    }
}
