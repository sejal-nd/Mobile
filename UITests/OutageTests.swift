//
//  OutageTests.swift
//  BGE
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class OutageTests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        doLoginAndNavigateToOutageTab()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func doLoginAndNavigateToOutageTab() {
        let continueButton = app.buttons["Continue"]
        XCTAssert(continueButton.waitForExistence(timeout: 30))
        
        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        app.switches.element(boundBy: 0).tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
        
        let signInButton = app.buttons["Sign In"]
        XCTAssert(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Outage"].tap()
    }
    
    func testOutageTabLayout() {
        XCTAssert(app.scrollViews.otherElements.buttons["Report outage"].waitForExistence(timeout: 5))
        XCTAssert(app.scrollViews.otherElements.buttons["View outage map"].waitForExistence(timeout: 5))
    }

}
