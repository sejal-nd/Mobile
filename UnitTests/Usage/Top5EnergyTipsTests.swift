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
        
        let expectedValues = [[
            EnergyTip(title: "short title", body: "short body"),
            EnergyTip(title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam blandit eros quis nisi rhoncus luctus. Nullam suscipit velit a hendrerit.", body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris blandit orci at sapien tempus malesuada. In sagittis nibh eu sapien volutpat facilisis. Duis volutpat mauris in sem mattis dignissim. Nullam eget venenatis quam. Nullam sodales id nisi euismod scelerisque. Maecenas ultricies malesuada fermentum. Donec ut commodo urna, eget accumsan ex. Vivamus non congue lacus."),
            EnergyTip(title: "Bold Italic", body: "This body has html formatting. This sentence is bold. This sentence is italic."),
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
        MockUser.current = MockUser(globalKeys: .energyTips3)
        MockAccountService.loadAccountsSync()
        
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: .default)
        
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
        MockUser.current = MockUser(globalKeys: .error)
        MockAccountService.loadAccountsSync()
        
        let viewModel = Top5EnergyTipsViewModel(usageService: MockUsageService(), accountDetail: .default)
        
        let expectedValues = ["fetch failed"]
        
        let observer = scheduler.createObserver([EnergyTip].self)
        viewModel.energyTips.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!zip(observer.events, expectedValues)
            .map { ($0.0.value.error as! ServiceError).serviceMessage == $0.1 }
            .contains(false))
    }
}
