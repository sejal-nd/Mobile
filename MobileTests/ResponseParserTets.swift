//
//  ResponseParserTets.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class ResponseParserTests: XCTestCase {
    
    let validSuccess: [String:Any] = [
        "success" : true,
    ]
    
    let validFailure: [String:Any] = [
        "success" : false,
        "meta":["code":"FN-ACC-LOCKED","description":"Account Locked"]
    ]
    
    func testValidSuccess() {
       
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: "", headerFields: ["":""])
        let result = OMCResponseParser.parse(data: validSuccess, error: nil, response: response)
             
        switch result {
        case .Failure( _):
            XCTFail("Incorrect Result - Valid Success response should result in a Success return value.")
            break
        case .Success:
            break
        }
    }
    
    func testValidFailure() {
        
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: "", headerFields: ["":""])
        let result = OMCResponseParser.parse(data: validFailure, error: nil, response: response)
        
        switch result {
        case .Failure:
            break
        case .Success:
            XCTFail("Incorrect Result - Valid Failure response should result in a Failure return value.")
            break
        }
    }
}
