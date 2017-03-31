//
//  OutageViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 3/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class OutageViewModelTests: XCTestCase {
    
    var viewModel: OutageViewModel!
    
    override func setUp() {
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: MockOutageService())
    }
    
    func testGetAccountsSuccess() {
        let asyncExpectation = expectation(description: "testGetAccountsSuccess")
        
        viewModel.getAccounts(onSuccess: { (accounts: [Account]) in
            asyncExpectation.fulfill()
        }, onError: { error in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusSuccess() {
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        
        let account = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        
        viewModel.getOutageStatus(forAccount: account!, onSuccess: { (status: OutageStatus) in
            asyncExpectation.fulfill()
        }, onError: { error in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
}
