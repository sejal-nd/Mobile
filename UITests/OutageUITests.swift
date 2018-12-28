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
        doLogin(username: "outageTestPowerOut")
        selectTab(tabName: "Outage")
        tapButton(buttonText: "Our records indicate your power is out")

        XCTAssertTrue(app.alerts.staticTexts["test power out message"].waitForExistence(timeout: 3))
    }
    
    func testGasOnlyState() {
        doLogin(username: "outageTestGasOnly")
        selectTab(tabName: "Outage")

        // Should not be an outage status button
        XCTAssertFalse(buttonElement(withText: "Our records indicate").exists)
        XCTAssertTrue(staticTextElement(withText: "This account receives gas service only").exists)
    }
    
    func testFinaledState() {
        doLogin(username: "outageTestFinaled")
        selectTab(tabName: "Outage")
        
        // Should not be an outage status button
        XCTAssertFalse(buttonElement(withText: "Our records indicate").exists)
            
        let reportOutageButton = buttonElement(withText: "Report outage")
        XCTAssertFalse(reportOutageButton.isEnabled, "Report outage button should be disabled for finaled accounts")
    }
    
    func testReportOutage() {
        doLogin(username: "outageTestReport")
        selectTab(tabName: "Outage")

        tapButton(buttonText: "Report outage")
        tapButton(buttonText: "Submit")

        checkExistenceOfElements([
            (.button, "Your outage is reported."),
            (.button, "Report outage. Reported")
        ])
    }
    
    func testMaintModeOutage() {
        doLogin(username: "maintNotHome")
        selectTab(tabName: "Outage")

        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Outage is currently unavailable due to")
        ])

        switch appOpCo {
        case .bge:
            //Parial string match needed to work around staticText 128 char query limit
            let outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your powe"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222")
        case .comEd:
            let outageMmStaticText = app.staticTexts["If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-334-7661 M-F 7AM to 7PM")
        default:
            let outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representati"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-494-4000 M-F 7AM to 7PM")
        }
    }
}
