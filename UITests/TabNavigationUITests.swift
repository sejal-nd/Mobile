//
//  TabNavigationUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class TabNavigationUITests: XCTestCase {
        
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        doLogin()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func doLogin() {
        let continueButton = app.buttons["Continue"]
        
        waitForElementToAppear(continueButton)
        
        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        app.switches.element(boundBy: 0).tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
        waitForElementToAppear(app.buttons["Sign In"])
        
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        waitForElementToAppear(app.buttons["Next:"])
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        waitForElementToAppear(app.tabBars.buttons["Home"])
    }
    
    func testHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testBillTab() {
        let billTab = app.tabBars.buttons["Bill"]
        billTab.tap()
        XCTAssertTrue(billTab.isSelected)
    }
    
    func testOutageTab() {
        let outageTab = app.tabBars.buttons["Outage"]
        outageTab.tap()
        XCTAssertTrue(outageTab.isSelected)
    }
    
    func testAlertsTab() {
        let alertsTab = app.tabBars.buttons["Alerts"]
        alertsTab.tap()
        XCTAssertTrue(alertsTab.isSelected)
    }
    
    func testMoreTab() {
        let moreTab = app.tabBars.buttons["More"]
        moreTab.tap()
        XCTAssertTrue(moreTab.isSelected)
    }
    
    //Helper function that waits for a specific element to appear
    func waitForElementToAppear (_ element: XCUIElement){
        let predicate = NSPredicate(format: "exists==true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
}
