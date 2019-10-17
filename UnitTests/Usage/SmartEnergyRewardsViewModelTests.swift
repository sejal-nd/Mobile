//
//  SERPTSGraphViewModelTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/26/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import RxCocoa

class SERPTSGraphViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    var scheduler = TestScheduler(initialClock: 0)
    var viewModel: SERPTSGraphViewModel!
    var eventResultsSubject = PublishSubject<[SERResult]>()
    
    lazy var dateFormatter = DateFormatter.mmDdYyyyFormatter
    
    lazy var hourDateFormatter = DateFormatter.MMddyyyyHHmmFormatter
    
    override func setUp() {
        super.setUp()
        
        //viewModel = SmartEnergyRewardsViewModel(accountDetailDriver: accountDetailSubject.asDriver(onErrorDriveWith: .empty()))
        viewModel = SERPTSGraphViewModel(eventResults: eventResultsSubject.asObservable())
    }
    
    private func scheduleBoilerplateEvents() {
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2016")!),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2017")!),
            SERResult(eventStart: dateFormatter.date(from: "02/23/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!)
        ]
        
        let eventResults4 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!),
            SERResult(eventStart: dateFormatter.date(from: "06/23/2018")!)
        ]
        
        let events = [
            [],
            [eventResults2.last!],
            eventResults2,
            eventResults4
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
    }
    
    func testLatest3EventsThisSeason() {
        scheduleBoilerplateEvents()
        
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
        
        XCTAssertRecordedElements(observer.events, expectedEvents)
    }
    
    func testNumBarsToShow() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(Int.self)
        viewModel.numBarsToShow.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, Array(0...3).enumerated().map(next))
    }
    
    func testShouldShowBar1() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar1.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, false, false, true].enumerated().map(next))
    }
    
    func testShouldShowBar2() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar2.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, false, true, true].enumerated().map(next))
    }
    
    func testShouldShowBar3() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBar3.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [false, true, true, true].enumerated().map(next))
    }
    
    func testBar1DollarLabelText() {
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 4),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 13.82),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 121),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 2)
        ]
        
        let events = [
            eventResults1,
            eventResults2,
            eventResults3
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar1DollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, "$2.00", "$13.82"].enumerated().map(next))
    }
    
    func testBar1DateLabelText() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar1DateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, nil, nil, "APR 23"].enumerated().map(next))
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
            eventResults1,
            eventResults2,
            eventResults3,
            eventResults4,
            eventResults5
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(CGFloat.self)
        viewModel.bar1HeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [121, 60.5, 3, 60.5, 3].enumerated().map(next))
    }
    
    func testBar2DollarLabelText() {
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 2)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 14.21),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 4)
        ]
        
        let events = [
            eventResults1,
            eventResults2,
            eventResults3
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar2DollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, "$2.00", "$14.21"].enumerated().map(next))
    }
    
    func testBar2DateLabelText() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar2DateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, nil, "FEB 23", "MAY 23"].enumerated().map(next))
    }
    
    func testBar2HeightConstraintValue() {
        
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 4),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "06/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 5)
        ]
        
        let eventResults4 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
        ]
        
        let eventResults5 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 6),
        ]
        
        let events = [
            eventResults1,
            eventResults2,
            eventResults3,
            eventResults4,
            eventResults5
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(CGFloat.self)
        viewModel.bar2HeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [121, 30.25, 72.6, 121, 60.5].enumerated().map(next))
    }
    
    func testBar3DollarLabelText() {
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 2)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 182.99)
        ]
        
        
        let events = [
            [],
            eventResults1,
            eventResults2,
            eventResults3
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar3DollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, "$2.00", "$1.00", "$182.99"].enumerated().map(next))
    }
    
    func testBar3DateLabelText() {
        scheduleBoilerplateEvents()
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.bar3DateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [nil, "MAY 23", "MAY 23", "JUN 23"].enumerated().map(next))
    }
    
    func testBar3HeightConstraintValue() {
        
        let eventResults1 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 3)
        ]
        
        let eventResults2 = [
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 4),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "06/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults3 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 1),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 4),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 2)
        ]
        
        let eventResults4 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3)
        ]
        
        let eventResults5 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 300),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 1)
        ]
        
        let eventResults6 = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 3),
        ]
        
        let events = [
            eventResults1,
            eventResults2,
            eventResults3,
            eventResults4,
            eventResults5,
            eventResults6
        ].enumerated().map(next)
        
        scheduler.createHotObservable(events)
            .bind(to: eventResultsSubject)
            .disposed(by: disposeBag)
        
        let observer = scheduler.createObserver(CGFloat.self)
        viewModel.bar3HeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [121, 30.25, 60.5, 121, 3, 121].enumerated().map(next))
    }
    
    func testBarDescriptionDateLabelText() {
        let eventResults = [
            SERResult(eventStart: dateFormatter.date(from: "03/21/2018")!, savingDollar: 2),
            SERResult(eventStart: dateFormatter.date(from: "04/23/2018")!, savingDollar: 3),
            SERResult(eventStart: dateFormatter.date(from: "05/23/2018")!, savingDollar: 4)
        ]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "May 23, 2018")
        }).disposed(by: disposeBag)
        
        viewModel.setBarSelected(tag: 0)
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "March 21, 2018")
        }).disposed(by: disposeBag)
        
        viewModel.setBarSelected(tag: 1)
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "April 23, 2018")
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionPeakHoursLabelText() {
        let startDate = hourDateFormatter.date(from: "03/21/2018 12:00")!
        let endDate = hourDateFormatter.date(from: "03/21/2018 19:00")!
        let eventResults = [
            SERResult(eventStart: startDate, eventEnd: endDate)
        ]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionPeakHoursLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "Peak Hours: 12PM - 7PM")
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionTypicalUseValueLabelText() {
        let eventResults = [SERResult(baselineKWH: 1029.21341)]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionTypicalUseValueLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "1029.2 kWh")
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionActualUseValueLabelText() {
        let eventResults = [SERResult(actualKWH: 18)]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionActualUseValueLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "18.0 kWh")
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionEnergySavingsValueLabelText() {
        let eventResults = [SERResult(savingKWH: 900.19)]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionEnergySavingsValueLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "900.2 kWh")
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionBillCreditValueLabelText() {
        let eventResults = [SERResult(savingDollar: 13.99)]
        
        viewModel = SERPTSGraphViewModel(eventResults: Observable.just(eventResults))
        
        viewModel.barDescriptionBillCreditValueLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "$13.99")
        }).disposed(by: disposeBag)
    }
    
    func testSetBarSelected() {
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value && i != 2 {
                XCTFail("All variables should be false initially except index 2")
            }
        }
        
        viewModel.setBarSelected(tag: 0)
        XCTAssert(viewModel.barGraphSelectionStates.value[0].value, "Index 0's value should be true")
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value && i != 0 {
                XCTFail("All variables should be false except index 0")
            }
        }
        
        viewModel.setBarSelected(tag: 1)
        XCTAssert(viewModel.barGraphSelectionStates.value[1].value, "Index 1's value should be true")
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value && i != 1 {
                XCTFail("All variables should be false except index 1")
            }
        }
    }
    
}
