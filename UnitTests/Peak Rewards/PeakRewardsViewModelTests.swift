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
    
    override func setUp() {
        super.setUp()
        AccountsStore.sharedInstance.currentAccount = Account.from(["accountNumber": "1234567890"])!
    }
    
    func testOverrides() {
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "", premiseNumber: ""))
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(1, 0), next(1, 1)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(SmartThermostatDevice.self)
        viewModel.selectedDevice.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [SmartThermostatDevice](repeating: SmartThermostatDevice(), count: 2).enumerated().map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testDeviceButtonText() {
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "", premiseNumber: ""))
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(1, 0), next(1, 1)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.deviceButtonText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [String](repeating: "Device: ", count: 2).enumerated().map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testProgramCardsDataActiveOverride() {
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "programCardsDataActiveOverride", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "programCardsDataNoOverrides", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "programCardsDataInactiveProgram", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "programCardsDataInactiveProgramScheduledOverride", premiseNumber: ""))
        
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
        let viewModel = PeakRewardsViewModel(peakRewardsService: MockPeakRewardsService(),
                                             accountDetail: AccountDetail(accountNumber: "programCardsDataInactiveProgramNoOverrides", premiseNumber: ""))
        
        scheduler.createHotObservable([next(0, ())])
            .bind(to: viewModel.loadInitialData)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)])
            .bind(to: viewModel.selectedDeviceIndex)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver([(String, String)].self)
        viewModel.programCardsData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [[("Test Program", "You have not been cycled today")]].enumerated().map(next)
        XCTAssert(!zip(observer.events, expectedEvents)
            .map {
                if let observedTupleArray = $0.0.value.element, let expectedTupleArray = $0.1.value.element {
                    return observedTupleArray[0] == expectedTupleArray[0]
                }
                return false
            }
            .contains(false))
    }
    
    

}
