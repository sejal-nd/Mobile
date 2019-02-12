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
    
    override func setUp() {
        super.setUp()
        launchApp()
    }
    
    func testOutageTabLayout() {
        doLogin(username: "valid@test.com")
        selectTab(tabName: "Outage")

        checkExistenceOfElements([
            (.button, "Report outage"),
            (.button, "View outage map")
        ])
    }
    
    func testPowerOnState() {
        doLogin(username: "outageTestPowerOn")
        selectTab(tabName: "Outage")
        tapButton(buttonText: "Outage status button. Our records indicate your power is on.")

        XCTAssertTrue(app.alerts.staticTexts["test power on message"].waitForExistence(timeout: 3))
    }
    
    func testPowerOutState() {
        doLogin(username: "outagePowerOut")
        selectTab(tabName: "Outage")
        tapButton(buttonText: "Outage status button. Our records indicate your power is out.")

        XCTAssertTrue(app.alerts.staticTexts["test power out message"].waitForExistence(timeout: 3))
    }
    
    func testGasOnlyState() {
        doLogin(username: "gasOnly")
        selectTab(tabName: "Outage")

        // Should not be an outage status button
        XCTAssertFalse(buttonElement(withText: "Our records indicate").exists)
        XCTAssertTrue(staticTextElement(withText: "Gas Only Account").exists)
    }
    
    func testFinaledState() {
        doLogin(username: "finaled")
        selectTab(tabName: "Outage")
        
        // Should not be an outage status button
        XCTAssertFalse(buttonElement(withText: "Our records indicate").exists)
            
        let reportOutageButton = buttonElement(withText: "Report outage")
        XCTAssertFalse(reportOutageButton.isEnabled, "Report outage button should be disabled for finaled accounts")
    }
    
    func testReportOutage() {
        doLogin(username: "default")
        selectTab(tabName: "Outage")

        tapButton(buttonText: "Report outage")
        tapButton(buttonText: "Submit")

        checkExistenceOfElements([
            (.button, "Your outage is reported."),
            (.button, "Report outage. Reported")
        ])
    }
}
