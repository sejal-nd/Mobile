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
    
    let validSuccessResponse: [String:Any] = [
        "success" : true,
        "data":["assertion":"token_value", "profileType": "residential", "profileStatus": [:], "customerIdentifier": "1234"]
    ]
    
    let noProfileTypeResponse: [String: Any] = [
        "success" : true,
        "data":["assertion":"token_value"]
    ]
    
    let invalidProfileTypeResponse: [String: Any] = [
        "success" : true,
        "data":["assertion":"token_value", "profileType": "wrong"]
    ]
    
    func testInvalidSuccessKey() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: invalidSuccessKeyFormat)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData)
            
            switch result {
            case .failure(let serviceError):
                XCTAssert(serviceError.serviceCode == ServiceErrorCode.parsing.rawValue, "Incorrect Result - ServiceError should be parse error")
            default:
                XCTFail("Unable to correctly parse a 'failure' response value - result should be success-false")
            }
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testValidFailedResponse() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: validFailedResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData)
            
            switch result {
            case .failure(let serviceError):
                XCTAssert(serviceError.localizedDescription == "Invalid user name or password")
            default:
                XCTFail("Unable to correctly parse a 'failure' response value - result should be success-false")
            }
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testValidSuccessResponse() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: validSuccessResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData)
            
            switch result {
            case .success(let value):
                XCTAssert(value.token == "token_value")
            default:
                XCTFail("Unable to correctly parse a 'success' response value - result should be success-true")
            }
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testNoProfileType() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: noProfileTypeResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData)
            
            switch result {
            case .success:
                XCTFail("Users with no profileType should not be able to log in")
            default:
                break
            }
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    func testInvalidProfileType() {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: invalidProfileTypeResponse)
            let result = AuthTokenParser.parseAuthTokenResponse(data: jsonData)
            
            switch result {
            case .success:
                XCTFail("Users with profileType not equal to \"residential\" or \"commercial\" should not be able to log in")
            default:
                break
            }
        } catch let err as NSError {
            XCTFail("Unable to parse " + err.localizedDescription)
        }
    }
    
    
}
