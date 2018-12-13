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
        let result = MCSResponseParser.parse(data: validSuccess)
             
        switch result {
        case .failure(_):
            XCTFail("Incorrect Result - Valid Success response should result in a Success return value.")
        case .success:
            break
        }
    }
    
    
    /// Test that an invalidly formatted response returns the correct error.
    func testInvalidSuccess() {
        let result = MCSResponseParser.parse(data: invalidSuccess)
        
        switch result {
        case .failure(let err):
            if(err.serviceCode != ServiceErrorCode.parsing.rawValue) {
                XCTFail("Incorrect Result - Invalid Success response should result in a parse error return value.")
            }
        case .success:
            XCTFail("Incorrect Result - Invalid response should result in a Failure return value.")
        }
    }
    
    
    /// Test that a failure in a valid format is correctly parsed.
    func testValidFailure() {
        let result = MCSResponseParser.parse(data: validFailure)
        
        switch result {
        case .failure:
            break
        case .success:
            XCTFail("Incorrect Result - Valid Failure response should result in a Failure return value.")
        }
    }
}
