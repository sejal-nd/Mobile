//
//  MyHomeProfileTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class MyHomeProfileTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    var scheduler: TestScheduler!
    let saveAction = PublishSubject<Void>()
    
    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        MockAccountService.loadAccountsSync()
    }
    
    func bind<T>(entries: [T], toVariable variable: Variable<T>, startTime: Int = 0, interval: Int = 1) {
        scheduler.createHotObservable(entries.enumerated().map { ($0 * interval + startTime, $1) }.map(next))
            .bind(to: variable)
            .disposed(by: disposeBag)
    }
    
    func bind<T>(entries: [T], toSubject subject: PublishSubject<T>, startTime: Int = 0, interval: Int = 1) {
        scheduler.createHotObservable(entries.enumerated().map { ($0 * interval + startTime, $1) }.map(next))
            .bind(to: subject)
            .disposed(by: disposeBag)
    }
    
    func testInitialHomeProfile() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        let observer = scheduler.createObserver(HomeProfile.self)
        viewModel.initialHomeProfile.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        var expectedEvents = [
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: 2,
                        squareFeet: 3000,
                        heatType: .electric,
                        homeType: .singleFamily)
            ]
            .enumerated()
            .map(next)
        
        expectedEvents.append(completed(0))
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testUpdatedHomeProfile() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [4], toVariable: viewModel.numberOfChildren, startTime: 1)
        bind(entries: [2], toVariable: viewModel.numberOfAdults, startTime: 2)
        bind(entries: ["3000"], toVariable: viewModel.homeSizeEntry, startTime: 3)
        bind(entries: [.electric], toVariable: viewModel.heatType, startTime: 4)
        bind(entries: [.singleFamily], toVariable: viewModel.homeType, startTime: 5)
        
        let observer = scheduler.createObserver(HomeProfile.self)
        viewModel.updatedHomeProfile.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [
            HomeProfile(numberOfChildren: nil,
                        numberOfAdults: nil,
                        squareFeet: nil,
                        heatType: nil,
                        homeType: nil),
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: nil,
                        squareFeet: nil,
                        heatType: nil,
                        homeType: nil),
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: 2,
                        squareFeet: nil,
                        heatType: nil,
                        homeType: nil),
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: 2,
                        squareFeet: 3000,
                        heatType: nil,
                        homeType: nil),
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: 2,
                        squareFeet: 3000,
                        heatType: .electric,
                        homeType: nil),
            HomeProfile(numberOfChildren: 4,
                        numberOfAdults: 2,
                        squareFeet: 3000,
                        heatType: .electric,
                        homeType: .singleFamily)
            ]
            .enumerated()
            .map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testHomeSizeError() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [nil, "fds", "49", "50", "1000001", "1000000"],
             toVariable: viewModel.homeSizeEntry)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.homeSizeError.subscribe(observer).disposed(by: disposeBag)
        
        var expectedEvents = [
                NSLocalizedString("Square footage is required", comment: ""),
                NSLocalizedString("Square footage is required", comment: ""),
                NSLocalizedString("Must be at least 50", comment: ""),
                nil,
                NSLocalizedString("Must be at most 1,000,000", comment: ""),
                nil
                ]
                .enumerated()
                .map(next)
        
        // Initial value of the Variable is nil
        expectedEvents.insert(next(0, NSLocalizedString("Square footage is required", comment: "")), at: 0)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testEnableSave() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [4], toVariable: viewModel.numberOfChildren, startTime: 1)
        bind(entries: [2], toVariable: viewModel.numberOfAdults, startTime: 2)
        
        // After this, homeSizeError != nil
        bind(entries: ["3000"], toVariable: viewModel.homeSizeEntry, startTime: 3)
        bind(entries: [.electric], toVariable: viewModel.heatType, startTime: 4)
        bind(entries: [.singleFamily], toVariable: viewModel.homeType, startTime: 5)
        
        // Now, make the initial and updated HomeProfiles unequal
        bind(entries: [5], toVariable: viewModel.numberOfChildren, startTime: 6)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.enableSave.subscribe(observer).disposed(by: disposeBag)
        
        let expectedEvents = [
            next(0, false),
            next(0, false),
            next(0, false),
            next(1, false),
            next(2, false),
            next(3, false),
            next(3, false),
            next(4, false),
            next(5, false),
            next(6, true)]
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testSaveSuccess() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [5], toVariable: viewModel.numberOfChildren, startTime: 1)
        bind(entries: [2], toVariable: viewModel.numberOfAdults, startTime: 1)
        bind(entries: ["3000"], toVariable: viewModel.homeSizeEntry, startTime: 1)
        bind(entries: [.electric], toVariable: viewModel.heatType, startTime: 1)
        bind(entries: [.singleFamily], toVariable: viewModel.homeType, startTime: 1)
        
        bind(entries: [()], toSubject: saveAction, startTime: 2)
        
        let observer = scheduler.createObserver(Void.self)
        viewModel.saveSuccess.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.filter { $0.value.element != nil }.count, 1)
    }
    
    func testSaveErrors() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [5], toVariable: viewModel.numberOfChildren, startTime: 1)
        bind(entries: [2], toVariable: viewModel.numberOfAdults, startTime: 1)
        // 500 causes an error in MockUsageService
        bind(entries: ["500"], toVariable: viewModel.homeSizeEntry, startTime: 1)
        bind(entries: [.electric], toVariable: viewModel.heatType, startTime: 1)
        bind(entries: [.singleFamily], toVariable: viewModel.homeType, startTime: 1)
        
        bind(entries: [()], toSubject: saveAction, startTime: 2)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.saveErrors.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [next(2, "LocalError")])
    }
    
    //MARK: - A11y
    
    func testSaveA11yLabel() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        scheduler.createHotObservable([next(1, HomeType.multiFamily)])
            .bind(to: viewModel.homeType)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(2, HeatType.electric)])
            .bind(to: viewModel.heatType)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(3, 4)])
            .bind(to: viewModel.numberOfAdults)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(4, 3)])
            .bind(to: viewModel.numberOfChildren)
            .disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(5, "3333")])
            .bind(to: viewModel.homeSizeEntry)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.saveA11yLabel.drive(observer).disposed(by: disposeBag)
        
        let expectedEvents = [
            "Home type is required,Heating fuel is required,Number of adults is required,Number of children is required,Square footage is required, Save Profile",
            "Heating fuel is required,Number of adults is required,Number of children is required,Square footage is required, Save Profile",
            "Number of adults is required,Number of children is required,Square footage is required, Save Profile",
            "Number of children is required,Square footage is required, Save Profile",
            "Square footage is required, Save Profile",
            "Save Profile"
        ].enumerated().map(next)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testHomeTypeA11y() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [nil, .multiFamily, .singleFamily],
             toVariable: viewModel.homeType)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.homeTypeA11y.drive(observer).disposed(by: disposeBag)
        
        var expectedEvents = [
            "Home Type, required",
            "Home Type, Apartment/Condo",
            "Home Type, House, Townhome, Row House"
            ]
            .enumerated()
            .map(next)
        
        // Initial value of the Variable is nil
        expectedEvents.insert(next(0, "Home Type, required"), at: 0)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testHeatingFuelA11y() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [nil, .naturalGas, .electric, .other, HeatType.none],
             toVariable: viewModel.heatType)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.heatingFuelA11y.drive(observer).disposed(by: disposeBag)
        
        var expectedEvents = [
            "Heating Fuel, required",
            "Heating Fuel, Natural Gas",
            "Heating Fuel, Electric",
            "Heating Fuel, Other",
            "Heating Fuel, None"
            ]
            .enumerated()
            .map(next)
        
        // Initial value of the Variable is nil
        expectedEvents.insert(next(0, "Heating Fuel, required"), at: 0)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testNumberOfAdultsA11y() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [2, 3], toVariable: viewModel.numberOfAdults, startTime: 1)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.numberOfAdultsA11y.drive(observer).disposed(by: disposeBag)
        
        let expectedEvents = [
            "Number of Adults, required",
            "Number of Adults, 2",
            "Number of Adults, 3"
            ]
            .enumerated()
            .map(next)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testNumberOfChildrenA11y() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: .default,
                                               saveAction: saveAction)
        
        bind(entries: [2, 3], toVariable: viewModel.numberOfChildren, startTime: 1)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.numberOfChildrenA11y.drive(observer).disposed(by: disposeBag)
        
        let expectedEvents = [
            "Number of Children, required",
            "Number of Children, 2",
            "Number of Children, 3"
            ]
            .enumerated()
            .map(next)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
}
