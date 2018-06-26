//
//  HomeBillCardUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class HomeBillCardUITests: ExelonUITestCase {
    
    func testNoDefaultPaymentSetWithBill() {
        doLogin(username: "billCardNoDefaultPayment")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Your bill is ready"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].waitForExistence(timeout: 3))
        
        let setDefaultPaymentAccountButton = app.scrollViews.otherElements.buttons["Set a default payment account"]
        setDefaultPaymentAccountButton.tap()
        
        XCTAssert(app.navigationBars["My Wallet"].waitForExistence(timeout: 3))
        app.navigationBars.buttons["Back"].tap()
        
        let slideToPayControl = app.scrollViews.otherElements["Slide to pay today"]
        XCTAssertFalse(slideToPayControl.isEnabled, "Slide to pay should be disabled when no default payment account")
    }
    
    func testDefaultPaymentSetWithBill() {
        doLogin(username: "billCardWithDefaultPayment")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Your bill is ready"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.scrollViews.otherElements.buttons["Set a default payment account"].exists, "Set payment account button should be hidden when one is already set")
        XCTAssert(app.scrollViews.otherElements.buttons["Bank account, Account ending in 1234"].exists, "Should display the default one touch pay account")
        XCTAssert(app.scrollViews.otherElements["Slide to pay today"].isEnabled, "Slide to pay should be enabled")
    }
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")
        
        let predicate = NSPredicate(format: "label CONTAINS 'Thank you for scheduling your $200.00 payment'")
        let thankYouButton = app.scrollViews.otherElements.buttons.element(matching: predicate)
        XCTAssert(thankYouButton.waitForExistence(timeout: 3))
        
        thankYouButton.tap()
        XCTAssert(app.navigationBars["Activity"].waitForExistence(timeout: 3))
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Thank you for your payment"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Past Due"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Immediately"].exists)
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due to Avoid Service Interruption"].waitForExistence(timeout: 3))
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due to Avoid Shutoff"].waitForExistence(timeout: 3))
        }
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Immediately"].exists)
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Your payment is processing"].waitForExistence(timeout: 3))
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Your payment is pending"].waitForExistence(timeout: 3))
        }
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
    }
    
    func testMaintModeHomeBillCard() {
        doLogin(username: "maintNotHome")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Billing is currently unavailable due to scheduled maintenance."].waitForExistence(timeout: 5))
    }
    
    func testMaintModeHome() {
        doLogin(username: "maintAllTabs")
        
        XCTAssert(app.buttons["Reload"].exists)
        XCTAssert(app.staticTexts["Scheduled Maintenance"].exists)
        XCTAssert(app.staticTexts["Home is currently unavailable due to\nscheduled maintenance."].waitForExistence(timeout: 5))
    }
    
    func testExpiredSlideToPay(){
        doLogin(username: "billCardWithExpiredDefaultPayment")
        
        //Assert slider is disabled since card is expired
        let slideToPayControl = app.scrollViews.otherElements["Slide to pay today"]
        XCTAssert(slideToPayControl.waitForExistence(timeout: 5))
        XCTAssertFalse(slideToPayControl.isEnabled, "Slider should be disabled when card is expired")
    }
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
}
