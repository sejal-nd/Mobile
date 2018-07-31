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
        var yyyyMMddFormatterDate = try? DateParser().extractDate(object: "2012/02/22323230")
        var yyyyMMddTHHmmssSSSFormatterDate = try? DateParser().extractDate(object: "122012-45/0202:30:05.0000000")
        var apiFormatDateDate = try? DateParser().extractDate(object: "2018-07-30T19:35:511111")
        var yyyyMMddTHHmmssZZZZZFormatterDate = try? DateParser().extractDate(object: "2018-07-30T19:35:51ZZZZZ")
        var yyyyMMddTHHmmssFormatterDate = try? DateParser().extractDate(object: "2018-07-30T19:35:511111")

        XCTAssertEqual(yyyyMMddFormatterDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssSSSFormatterDate, nil)
        XCTAssertEqual(apiFormatDateDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssZZZZZFormatterDate, nil)
        XCTAssertEqual(yyyyMMddTHHmmssFormatterDate, nil)
    }
    
    func testyyyyMMddFormatter() {
        var formatterDate = try? DateParser().extractDate(object: "2012/02/22")

        var dateComponents = DateComponents()
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }
    
    func testyyyyMMddTHHmmssFormatter() {
        var formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00.000")
        
        var dateComponents = DateComponents()
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)
        
        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testyyyyMMddTHHmmssZZZZZFormatter() {
        var formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00Z")
        
        var dateComponents = DateComponents()
        dateComponents.timeZone = .gmt
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.current.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testapiFormatDate() {
        var formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00")
        
        var dateComponents = DateComponents()
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }

    func testyyyyMMddTHHmmssSSSFormatter() {
        var formatterDate = try? DateParser().extractDate(object: "2012-02-22T01:02:00.000")
        
        var dateComponents = DateComponents()
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        dateComponents.hour = 01
        dateComponents.minute = 02
        let desiredDate = Calendar.opCo.date(from: dateComponents)

        XCTAssertEqual(formatterDate, desiredDate)
    }
    
}
