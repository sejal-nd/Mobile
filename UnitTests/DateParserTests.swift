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
        var yyyyMMddFormatterDate = try? DateParser().extractDate(object: "2012/02/22")

        var dateComponents = DateComponents()
        dateComponents.year = 2012
        dateComponents.month = 02
        dateComponents.day = 22
        let yyyyMMddFormatterDesiredDate = Calendar.current.date(from: dateComponents)

        XCTAssertEqual(yyyyMMddFormatterDate, yyyyMMddFormatterDesiredDate)
    }
    
//    func testyyyyMMddTHHmmssFormatter() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testyyyyMMddTHHmmssZZZZZFormatter() {
//
//    }
//
//    func testapiFormatDate() {
//
//    }
//
//    func testyyyyMMddTHHmmssSSSFormatter() {
//
//    }
    
}
