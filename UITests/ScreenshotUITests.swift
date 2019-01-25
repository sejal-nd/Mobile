//
//  ScreenshotUITests.swift
//  BGE
//
//  Created by Joseph Erlandson on 1/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
import LocalAuthentication

class ScreenshotUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        doLogin(username: "valid@test.com") // todo replace with Sam's app store account mock
        
        setupSnapshot(app)
        
        continueAfterFailure = false
    }
    
    func testScreenshots() {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        snapshot("0-Home")
        XCTAssertTrue(homeTab.isSelected)
        
        let billTab = app.tabBars.buttons["Bill"]
        billTab.tap()
        snapshot("1-Bill")
        XCTAssertTrue(billTab.isSelected)
        
        let outageTab = app.tabBars.buttons["Outage"]
        outageTab.tap()
        snapshot("2-Outage")
        XCTAssertTrue(outageTab.isSelected)
        
        let usageTab = app.tabBars.buttons["Usage"]
        usageTab.tap()
        snapshot("3-Usage")
        XCTAssertTrue(usageTab.isSelected)
        
        // todo navigate to storm mode screen
        
        // **idea**
        let moreTab = app.tabBars.buttons["More"]
        moreTab.tap()
        XCTAssertTrue(moreTab.isSelected)
        
        tapButton(buttonText: "Sign Out")
        
        let alert = app.alerts["Sign Out"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["No"].exists)
        XCTAssertTrue(alert.buttons["Yes"].exists)
        
        // Test "Yes" tap
        alert.buttons["Yes"].tap()
        XCTAssertFalse(alert.exists)
        
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 5))

        // switch status bool
        StormModeStatus.shared.isOn = true // switch

        doLogin(username: "valid@test.com")

        snapshot("4-StormMode")
    }
        
}
