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
        "success" : true
    ]
    
    let invalidSuccess: [String:Any] = [
        "success" : "true" //Invalid type - string
    ]
    
    let validFailure: [String:Any] = [
        "success" : false,
        "meta":["code":"FN-ACC-LOCKED","description":"Account Locked"]
    ]
    
    
    /// Test that a valid success response is correctly parsed.
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
    
    
    /// Test that an invalidly formatted response returns the correct error.
    func testInvalidSuccess() {
        
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: "", headerFields: ["":""])
        let result = OMCResponseParser.parse(data: invalidSuccess, error: nil, response: response)
        
        switch result {
        case .Failure(let err):
            if(err.serviceCode != ServiceErrorCode.Parsing.rawValue) {
                XCTFail("Incorrect Result - Invalid Success response should result in a parse error return value.")
            }
            break
        case .Success:
            XCTFail("Incorrect Result - Invalid response should result in a Failure return value.")
            break
        }
    }
    
    
    /// Test that a failure in a valid format is correctly parsed.
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
    
    
    /// Test that if an error is passed to the parse
    /// function, regardless of data. The error is returned
    /// in a failure response.
    func testError() {
        
        let response = HTTPURLResponse(url: URL(string: "http://test.com")!, statusCode: 200, httpVersion: "", headerFields: ["":""])
        let error = NSError(domain: "testing", code: 1, userInfo: [NSLocalizedDescriptionKey:"error description"])
        let result = OMCResponseParser.parse(data: validFailure, error: error, response: response)
 
        switch result {
        case .Failure(let err):
            XCTAssert(err.localizedDescription == "Account Locked", "Incorrect error description")
            break
        case .Success:
            XCTFail("Incorrect Result - Valid Failure response should result in a Failure return value.")
            break
        }
    }
}
