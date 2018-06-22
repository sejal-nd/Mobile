//
//  OutageTests.swift
//  BGE
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
class OutageUITests: ExelonUITestCase {
    
    
    
    func testOutageTabLayout() {
        doLogin(username: "valid@test.com")
        selectTab(tabName: "Outage")
        
        XCTAssert(app.scrollViews.otherElements.buttons["Report outage"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.buttons["View outage map"].waitForExistence(timeout: 3))
    }
    
    func testPowerOnState() {
        doLogin(username: "outageTestPowerOn")
        selectTab(tabName: "Outage")
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate your power is on'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 5))
        
        outageStatusButton.tap()
        XCTAssert(app.alerts.staticTexts["test power on message"].waitForExistence(timeout: 3))
    }
    
    func testPowerOutState() {
        doLogin(username: "outageTestPowerOut")
        selectTab(tabName: "Outage")
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate your power is out'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(outageStatusButton.waitForExistence(timeout: 5))
        
        outageStatusButton.tap()
        XCTAssert(app.alerts.staticTexts["test power out message"].waitForExistence(timeout: 3))
    }
    
    func testGasOnlyState() {
        doLogin(username: "outageTestGasOnly")
        selectTab(tabName: "Outage")
        let predicate = NSPredicate(format: "label CONTAINS 'Our records indicate'")
        let outageStatusButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssertFalse(outageStatusButton.waitForExistence(timeout: 3)) // Should not be an outage status button
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["This account receives gas service only"].waitForExistence(timeout: 3))
    }
    
    func testFinaledState() {
        doLogin(username: "outageTestFinaled")
        selectTab(tabName: "Outage")
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
        selectTab(tabName: "Outage")
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
        selectTab(tabName: "Outage")
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
