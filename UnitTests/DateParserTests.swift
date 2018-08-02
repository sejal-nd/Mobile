//
//  DateParserTests.swift
//  BGEUnitTests
//
//  Created by Joseph Erlandson on 7/30/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class DateParserTests: XCTestCase {

    func testInvalidDateString() {
        let yyyyMMddFormatterDate = try? DateParser().extractDate(object: "2012/02/22323230")
        let yyyyMMddTHHmmssSSSFormatterDate = try? DateParser().extractDate(object: "122012-45/0202:30:05.0000000")
        let apiFormatDateDate = try? DateParser().extractDate(object: "2018-07-30T19:35:511111")
        let yyyyMMddTHHmmssZZZZZFormatterDate = try? DateParser().extractDate(object: "2018-07-30T19:35:51ZZZZZ")
        let HHmmFormatterDate = try? DateParser().extractDate(object: "011212:021221212Z")
        let yyyyMMddTHHmmssZFormatterFormatterDate = try? DateParser().extractDate(object: "20121212-02222-22222T02222:32:00ZZZ")

        XCTAssertEqual(yyyyMMddFormatterDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssSSSFormatterDate, nil)
        XCTAssertEqual(apiFormatDateDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssZZZZZFormatterDate, nil)
        XCTAssertEqual(HHmmFormatterDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssZFormatterFormatterDate, nil)
    }
    
    func testyyyyMMddFormatter() {
        let formatterDate = try? DateParser().extractDate(object: "2012/02/22")

        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testyyyyMMddTHHmmssZZZZZFormatter() {
        let formatterDate = try? DateParser().extractDate(object: "2012-02-22T06:02:00Z")
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testapiFormatDate() {
        let formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00")
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testyyyyMMddTHHmmssSSSFormatter() {
        let formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00.000")
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testHHmmFormatter() {
        let formatterDate = try? DateParser().extractDate(object: "01:02")
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2000
        dateComponents.month = 01
        dateComponents.day = 01
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }
    
    func testyyyyMMddTHHmmssZFormatter() {
        let formatterDate = try? DateParser().extractDate(object: "2012-02-02T06:01:00Z")

        var dateComponents = DateComponents()
        dateComponents.timeZone = .opCo
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 02
        dateComponents.hour = 01
        dateComponents.minute = 01
        let desiredDate = Calendar.opCo.date(from: dateComponents)
        
        XCTAssertEqual(formatterDate, desiredDate)
    }
    
}
