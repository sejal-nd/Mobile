//
//  PeakRewardsViewModelTests.swift
//  Mobile
//
//  Created by Samuel Francis on 2/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class PeakRewardsViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    var scheduler = TestScheduler(initialClock: 0)
    
    func testOverrides() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([PeakRewardsOverride].self)
        viewModel.overrides.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedValues = [[PeakRewardsOverride()]]
        XCTAssertEqual(observer.events.count, expectedValues.count)
        XCTAssert(!zip(observer.events, expectedValues)
            .map { $0.0.value.element! == $0.1 }
            .contains(false))
    }
    
    func testDevices() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([SmartThermostatDevice].self)
        viewModel.devices.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedValues = [[SmartThermostatDevice(), SmartThermostatDevice()]]
        XCTAssertEqual(observer.events.count, expectedValues.count)
        XCTAssert(!zip(observer.events, expectedValues)
            .map { $0.0.value.element! == $0.1 }
            .contains(false))
    }
    
    func testSelectedDevice() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(1, 0), next(1, 1)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(SmartThermostatDevice.self)
        viewModel.selectedDevice.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedElements = [SmartThermostatDevice](repeating: SmartThermostatDevice(), count: 2)
        XCTAssertRecordedElements(observer.events, expectedElements)
    }
    
    func testDeviceButtonText() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(1, 0), next(1, 1)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.deviceButtonText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedElements = [String](repeating: "Device: ", count: 2)
        XCTAssertRecordedElements(observer.events, expectedElements)
    }
    
    func testProgramCardsDataActiveOverride() {
        MockUser.current = MockUser(dataKeys: [.peakRewardsSummary: .peakRewardsInactiveProgram,
                                               .peakRewardsOverrides: .peakRewardsActiveOverride])
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [[("Test Program", "Override scheduled for today")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    func testProgramCardsDataNoOverrides() {
        MockUser.current = MockUser(dataKeys: [.peakRewardsSummary: .peakRewardsActiveProgram,
                                               .peakRewardsOverrides: .peakRewardsNoOverrides])
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()

        let expectedEvents = [[("Test Program", "Currently cycling")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    func testProgramCardsDataInactiveProgramActiveOverride() {
        MockUser.current = MockUser(dataKeys: [.peakRewardsSummary: .peakRewardsInactiveProgram,
                                               .peakRewardsOverrides: .peakRewardsActiveOverride])
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [[("Test Program", "Override scheduled for today")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    func testProgramCardsDataInactiveProgramScheduledOverride() {
        MockUser.current = MockUser(dataKeys: [.peakRewardsSummary: .peakRewardsInactiveProgram,
                                               .peakRewardsOverrides: .peakRewardsScheduledOverride])
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [[("Test Program", "You have been cycled today")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    func testProgramCardsDataInactiveProgramNoOverrides() {
        MockUser.current = MockUser(dataKeys: [.peakRewardsSummary: .peakRewardsInactiveProgram,
                                               .peakRewardsOverrides: .peakRewardsNoOverrides])
        MockAccountService.loadAccountsSync()
        
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [[("Test Program", "You have been cycled today")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    func testShowDeviceButton() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        // Test case: devices.count > 1, should show
        var viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        var observer = scheduler.createObserver(Bool.self)
        viewModel.showDeviceButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, [true])
        XCTAssertEqual(observer.events, [true].enumerated().map(next))
        
        MockUser.current = MockUser(globalKeys: .peakRewardsActiveProgram)
        MockAccountService.loadAccountsSync()
        
        // Test case: devices.count == 1, should not show
        viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: .default)
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        observer = scheduler.createObserver(Bool.self)
        viewModel.showDeviceButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, [false])
    }
    
}
