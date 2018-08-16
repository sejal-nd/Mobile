//
//  OutageTests.swift
//  BGE
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
class OutageUITests: XCTestCase {
    
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
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func doLogin(username: String) {
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
        usernameEmailAddressTextField.clearAndEnterText(username)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Outage"].tap()
    }
    
    func testOutageTabLayout() {
        doLogin(username: "valid@test.com")
        
        XCTAssert(app.scrollViews.otherElements.buttons["Report outage"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.buttons["View outage map"].waitForExistence(timeout: 3))
    }
    
    func testPowerOnState() {
        doLogin(username: "outageTestPowerOn")
        
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate your power is on'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 5))
        
        outageStatusButton.tap()
        XCTAssert(app.alerts.staticTexts["test power on message"].waitForExistence(timeout: 3))
    }
    
    func testPowerOutState() {
        doLogin(username: "outageTestPowerOut")
        
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate your power is out'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 5))
        
        outageStatusButton.tap()
        XCTAssert(app.alerts.staticTexts["test power out message"].waitForExistence(timeout: 3))
    }
    
    func testGasOnlyState() {
        doLogin(username: "outageTestGasOnly")
        
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssertFalse(outageStatusButton.waitForExistence(timeout: 3)) // Should not be an outage status button
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["This account receives gas service only"].waitForExistence(timeout: 3))
    }
    
    func testFinaledState() {
        doLogin(username: "outageTestFinaled")
        
        let predicate = NSPredicate(format: "label CONTAINS 'available for this account.'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 3))
            
        outageStatusButton.tap()
        XCTAssert(app.alerts.count == 0, "Should be no alert when tapping")
            
        let reportOutageButton = app.scrollViews.otherElements.buttons["Report outage"]
        XCTAssertFalse(reportOutageButton.isEnabled, "Report outage button should be disabled for finaled accounts")
    }
    
    func testReportOutage() {
        doLogin(username: "outageTestReport")
        
        let reportOutageButton = app.scrollViews.otherElements.buttons["Report outage"]
        _ = reportOutageButton.waitForExistence(timeout: 3)
        reportOutageButton.tap()
        
        let submitButton = app.navigationBars.buttons["Submit"]
        _ = submitButton.waitForExistence(timeout: 3)
        submitButton.tap()
        
        var predicate = NSPredicate(format: "label CONTAINS 'Your outage is reported.'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 3), "Expected the outage status button in the reported state")
        
        predicate = NSPredicate(format: "label CONTAINS 'Report outage. Reported'")
        XCTAssert(app.scrollViews.otherElements.buttons.element(matching: predicate).waitForExistence(timeout: 3), "Expected the report outage button in the reported state")
    }
    
    func testMaintModeOutage() {
        doLogin(username: "maintNotHome")
        
        XCTAssert(app.buttons["Reload"].exists)
        XCTAssert(app.staticTexts["Scheduled Maintenance"].exists)
        XCTAssert(app.staticTexts["Outage is currently unavailable due to\nscheduled maintenance."].exists)
        var outageMmStaticText: XCUIElement
        
        if appName.contains("BGE") {
            //Parial string match needed to work around staticText 128 char query limit
            outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your powe"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222")
        }
        else if appName.contains("ComEd") {
            outageMmStaticText = app.staticTexts["If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-334-7661 M-F 7AM to 7PM")
        }
        else {
           outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representati"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-494-4000 M-F 7AM to 7PM")
        }
    }
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }

}
