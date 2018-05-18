//
//  BillUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
class BillUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        ACTLaunch.launch(app)
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
        
        let billTab = app.tabBars.buttons["Bill"]
        XCTAssert(billTab.waitForExistence(timeout: 10))
        billTab.tap()
    }
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: Date())
        XCTAssert(app.scrollViews.otherElements.buttons["Thank you for scheduling your $200.00 payment for \(dateString)"].waitForExistence(timeout: 3))
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: Date())
        XCTAssert(app.scrollViews.otherElements.buttons["Thank you for $200.00 payment on \(dateString)"].waitForExistence(timeout: 3))
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Past Due"].waitForExistence(timeout: 3))
        XCTAssert(app.scrollViews.otherElements.staticTexts["Total Amount Due Immediately"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Immediately"].exists)
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due to Avoid Service Interruption"].waitForExistence(timeout: 3))
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment due to avoid shut-off is $200.00 due immediately."].waitForExistence(timeout: 3))
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due to Avoid shut-off"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Immediately"].exists)
        }
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Processing"].waitForExistence(timeout: 3))
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Pending Payment"].waitForExistence(timeout: 3))
        }
        XCTAssert(app.scrollViews.otherElements.staticTexts["-$200.00"].exists)
    }
    
    func testMaintModeBill() {
        doLogin(username: "maintNotHome")
        
        XCTAssert(app.buttons["Reload"].exists)
        XCTAssert(app.staticTexts["Scheduled Maintenance"].exists)
        XCTAssert(app.staticTexts["Billing is currently unavailable due to\nscheduled maintenance."].exists)
    }
    
    func testExpiredCc() {
        let alertsQuery = app.alerts
        let elementsQuery = app.scrollViews.otherElements
        var predicate: NSPredicate
        doLogin(username: "billCardWithExpiredDefaultPayment")
        
        //Check for expired card warning
        app.buttons["My Wallet"].tap()
        let alert = alertsQuery.staticTexts["Please update your Wallet as one or more of your saved payment accounts have expired."]
        XCTAssert(alert.waitForExistence(timeout: 2))
        let okButton = alertsQuery.buttons["OK"]
        okButton.tap()
        
        //Check for "Expired" label on the button
        if appName.contains("BGE"){
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, EXPIRED CARD, Account number ending in, 1234, Default payment account, Fees: $0.00 Residential | 0% Business'")
        } else {
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, EXPIRED CARD, Account number ending in, 1234, Default payment account, $0.00 Convenience Fee'")
        }
        let expiredCardButton = app.tables.cells.buttons.element(matching: predicate)
        
        expiredCardButton.tap()
        XCTAssert(elementsQuery.staticTexts["Expired"].exists)
        let cancelButton = app.navigationBars["Edit Card"].buttons["Cancel"]
        cancelButton.tap()
    }
    
    func testCvvText() {
        var predicate: NSPredicate
        let elementsQuery = app.scrollViews.otherElements
        doLogin(username: "billCardWithDefaultCcPayment")
        app.buttons["My Wallet"].tap()
        
        if appName.contains("BGE"){
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, TEST NICKNAME, Account number ending in, 1234, Default payment account, Fees: $0.00 Residential | 0% Business'")
            let expiredCardButton = app.tables.cells.buttons.element(matching: predicate)
            expiredCardButton.tap()
            elementsQuery.buttons["Tool tip"].tap()
            XCTAssert(elementsQuery.staticTexts["Your security code is usually a 3 or 4 digit number found on your card."].exists)
        } else {
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, TEST NICKNAME, Account number ending in, 1234, Default payment account, $0.00 Convenience Fee'")
            let expiredCardButton = app.tables.cells.buttons.element(matching: predicate)
            expiredCardButton.tap()
            elementsQuery.buttons["Tool tip"].tap()
            XCTAssert(elementsQuery.staticTexts["Your security code is usually a 3 digit number found on the back of your card."].exists)
        }
    }
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
    
}
