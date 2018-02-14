//
//  HomeBillCardUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class HomeBillCardUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
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
    }
    
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
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due to Avoid Service Interruption"].waitForExistence(timeout: 3))
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
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
    
    
}
