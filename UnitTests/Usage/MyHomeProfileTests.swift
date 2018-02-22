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
    }
    
    func bind<T>(entries: [T], toVariable variable: Variable<T>) {
        scheduler.createHotObservable(entries.enumerated().map(next))
            .bind(to: variable)
            .disposed(by: disposeBag)
    }
    
    func testInitialHomeProfile() {
        XCTFail()
    }
    
    func testUpdatedHomeProfile() {
        XCTFail()
    }
    
    func testHomeSizeError() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: AccountDetail(accountNumber: "",
                                                                            premiseNumber: ""),
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
        XCTFail()
    }
    
    func testSaveSuccess() {
        XCTFail()
    }
    
    func testSaveErrors() {
        XCTFail()
    }
    
    //MARK: - A11y
    
    func testSaveA11yLabel() {
        let viewModel = MyHomeProfileViewModel(usageService: MockUsageService(),
                                               accountDetail: AccountDetail(accountNumber: "",
                                                                            premiseNumber: ""),
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
            "Home type is required,Heating fuel is required,Number of adults is required,Number of children is required,Square footage is required, Save",
            "Heating fuel is required,Number of adults is required,Number of children is required,Square footage is required, Save",
            "Number of adults is required,Number of children is required,Square footage is required, Save",
            "Number of children is required,Square footage is required, Save",
            "Square footage is required, Save",
            "Save"
            ]
            .enumerated()
            .map(next)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testHomeTypeA11y() {
        XCTFail()
    }
    
    func testHeatingFuelA11y() {
        XCTFail()
    }
    
    func testNumberOfAdultsA11y() {
        XCTFail()
    }
    
    func testNumberOfChildrenA11y() {
        XCTFail()
    }
}
