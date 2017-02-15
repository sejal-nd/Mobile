//
//  AuthTokenParserTests.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class AuthTokenParserTests: XCTestCase {
    
    let invalidSuccessKeyFormat: [String:Any] = [
        "success" : "false", //this key should not be a string
        "meta":["code":"FN-CRED-INVALID","description":"Invalid user name or password"]
    ]
    
    let validFailedResponse: [String:Any] = [
        "success" : false,
        "meta":["code":"FN-CRED-INVALID","description":"Invalid user name or password"]
    ]
    
    let validSucessResponse: [String:Any] = [
        "success" : true,
        "data":["assertion":"token_value"]
    ]
    
    func testInvalidSuccessKey() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: invalidSuccessKeyFormat)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData, response: nil, error: nil)
            
            switch result {
            case .Failure(let serviceError):
                switch(serviceError) {
                case .JSONParsing:
                    break;
                default:
                    XCTFail("Incorrect Result - ServiceError should be .JSONParsing")
                }
            default:
                XCTFail("Unable to correctly parse a 'failure' response value - result should be success-false")
            }
            
            print(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) ?? "No Response Data")
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testValidFailedResponse() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: validFailedResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData, response: nil, error: nil)
            
            switch result {
            case .Failure(let serviceError):
                switch(serviceError) {
                case .Custom(let code, let description):
                    XCTAssert(code == "FN-CRED-INVALID")
                    XCTAssert(description == "Invalid user name or password")
                default:
                    XCTFail("Incorrect Result")
                }
            default:
                XCTFail("Unable to correctly parse a 'failure' response value - result should be success-false")
            }
            
            print(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) ?? "No Response Data")
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testValidSuccessResponse() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: validSucessResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData, response: nil, error: nil)
            
            switch result {
            case .Success(let value):
                XCTAssert(value == "token_value")
            default:
                XCTFail("Unable to correctly parse a 'success' response value - result should be success-true")
            }
            
            print(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) ?? "No Response Data")
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    
}
