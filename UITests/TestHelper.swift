//
//  TestHelper.swift
//  BGE
//
//  Created by Peter Harris on 6/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import AppCenterXCUITestExtensions
import XCTest

class ExelonUITestCase: XCTestCase{
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        ACTLaunch.launch(app)
    }
    
    override func tearDown() {
        ACTLabel.labelStep("Tearing down")
        
        super.tearDown()
    }
    
    func handleTermsFirstLaunch() {
        
        let continueButton = app.buttons["Continue"]
        XCTAssert(continueButton.waitForExistence(timeout: 30))
        
        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        app.switches.element(boundBy: 0).tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
        XCTAssert(app.buttons["Sign In"].waitForExistence(timeout: 5))
    }
    
    func doLogin(username: String) {
    
        handleTermsFirstLaunch()
    
        let signInButton = app.buttons["Sign In"]
        XCTAssert(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText(username)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
    
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
    
    
    }

    func selectTab(tabName: String){
        let tab = app.tabBars.buttons[tabName]
        XCTAssert(tab.waitForExistence(timeout: 10))
        tab.tap()
    }
    
    func tapButton(buttonText: String){
        let makePaymentButton = app.scrollViews.otherElements.buttons[buttonText]
        XCTAssert(makePaymentButton.waitForExistence(timeout: 3))
        makePaymentButton.tap()
    }
}
