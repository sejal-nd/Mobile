//
//  SmartEnergyRewardsViewModelTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class SmartEnergyRewardsViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    var scheduler = TestScheduler(initialClock: 0)
    var viewModel: SmartEnergyRewardsViewModel!
    var accountDetailSubject = PublishSubject<AccountDetail>()
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    override func setUp() {
        super.setUp()
        viewModel = SmartEnergyRewardsViewModel(accountDetailDriver: accountDetailSubject.asDriver(onErrorDriveWith: .empty()))
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2016")!),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2017")!),
            SERResult(eventStart: dateFormatter.date(from: "02/23/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!)
        ]
        
        let eventStart = dateFormatter.date(from: "04/23/2018")!
        let endTimeAddComponents = DateComponents(calendar: Calendar.opCo, timeZone: .opCo, hour: 17)
        let eventEnd = Calendar.opCo.date(byAdding: endTimeAddComponents, to: eventStart)!
        
        let eventResults4 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!),
            SERResult(eventStart: eventStart, eventEnd: eventEnd),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "06/23/2018")!)
        ]
        
        let events = [
            AccountDetail(serInfo: SERInfo()),
            AccountDetail(serInfo: SERInfo(eventResults: [eventResults2.last!])),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults2)),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults4))
            ]
            .enumerated()
            .map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: accountDetailSubject)
            .disposed(by: disposeBag)
    }
    
    func testLatest3EventsThisSeason() {
        let expectedEvents = [
            [],
            [
                SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!)
            ],
            [
                SERResult(eventStart: dateFormatter.date(from: "02/23/2018")!),
                SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!)
            ],
            [
                SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!),
                SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!),
                SERResult(eventStart: dateFormatter.date(from: "06/23/2018")!)
            ]
            ]
        
        let observer = scheduler.createObserver([SERResult].self)
        viewModel.latest3EventsThisSeason.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!observer.events
            .map { ($0.time, $0.value.element!) }
            .map { $0.1 == expectedEvents[$0.0] }
            .contains(false))
    }
    
    func testNumBarsToShow() {
        let observer = scheduler.createObserver(Int.self)
        viewModel.numBarsToShow.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, Array(0...3).enumerated().map(next))
    }
    
    func testShouldShowBar1() {
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar1.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, false, false, true].enumerated().map(next))
    }
    
    func testShouldShowBar2() {
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar2.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, false, true, true].enumerated().map(next))
    }
    
    func testShouldShowBar3() {
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar3.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, true, true, true].enumerated().map(next))
    }
    
    func testBar1HeightConstraintValue() {
        
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 4),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 121),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 2)
        ]
        
        let eventResults4 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 4)
        ]
        
        let eventResults5 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 121)
        ]
        
        let events = [
            AccountDetail(serInfo: SERInfo(eventResults: eventResults1)),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults2)),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults3)),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults4)),
            AccountDetail(serInfo: SERInfo(eventResults: eventResults5))
            ]
            .enumerated()
            .map { ($0.0 + 4, $0.1) }
            .map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: accountDetailSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(CGFloat.self)
        viewModel.bar1HeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [0, 0, 0, 121, 121, 60.5, 3, 60.5, 3].enumerated().map(next))
    }
    
    func testBar1A11yLabel() {
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar1A11yLabel.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedStrings = [
            nil, nil, nil,
            "April 23, 2018. Peak Hours: 12AM - 5PM. Typical use: 0.0 kWh. Actual use: 0.0 kWh. Energy savings: 0.0 kWh. Bill credit: $0.00"
        ]
        
        XCTAssertEqual(observer.events, expectedStrings.enumerated().map(next))
    }
    
}
