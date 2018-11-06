//
//  BillUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
class BillUITests: ExelonUITestCase {
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")
        selectTab(tabName: "Bill")

        let buttonText = "Thank you for scheduling your $82.00 payment for \(dateString(from: Date()))"
        XCTAssert(buttonElement(withText: buttonText).exists)
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")
        selectTab(tabName: "Bill")

        let buttonText = "Thank you for $200.00 payment on \(dateString(from: Date()))"
        XCTAssert(buttonElement(withText: buttonText).exists)
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")
        selectTab(tabName: "Bill")
        
        XCTAssert(staticTextElement(withText: "Amount Past Due").exists)
        XCTAssert(staticTextElement(withText: "Total Amount Due Immediately").exists)
        XCTAssert(staticTextElement(withText: "$200.00").exists)
        XCTAssert(staticTextElement(withText: "Due Immediately").exists)
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")
        selectTab(tabName: "Bill")
        
        if appName.contains("BGE") {
            XCTAssert(staticTextElement(withText: "Amount Due to Avoid Service Interruption").exists)
        } else {
            XCTAssert(staticTextElement(withText: "Payment due to avoid shut-off is $200.00 due immediately.").exists)
            XCTAssert(staticTextElement(withText: "Amount Due to Avoid shut-off", timeout: 0.1).exists)
            XCTAssert(staticTextElement(withText: "Due Immediately", timeout: 0.1).exists)
        }

        XCTAssert(staticTextElement(withText: "$200.00", timeout: 0.1).exists)
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")
        selectTab(tabName: "Bill")
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Processing"].waitForExistence(timeout: 3))
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Pending Payment"].waitForExistence(timeout: 3))
        }
        XCTAssert(app.scrollViews.otherElements.staticTexts["-$200.00"].exists)
    }
    
    func testMaintModeBill() {
        doLogin(username: "maintNotHome")
        selectTab(tabName: "Bill")
        
        XCTAssert(app.buttons["Reload"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Scheduled Maintenance"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Billing is currently unavailable due to\nscheduled maintenance."].waitForExistence(timeout: 5))
    }
    
    func testExpiredCc() {
        let alertsQuery = app.alerts
        let elementsQuery = app.scrollViews.otherElements
        var predicate: NSPredicate
        doLogin(username: "billCardWithExpiredDefaultPayment")
        selectTab(tabName: "Bill")
        
        //Check for expired card warning
        app.buttons["My Wallet"].tap()
        let alert = alertsQuery.staticTexts["Please update your Wallet as one or more of your saved payment accounts have expired."]
        XCTAssert(alert.waitForExistence(timeout: 2))
        let okButton = alertsQuery.buttons["OK"]
        okButton.tap()
        
        //Check for "Expired" label on the button
        if appName.contains("BGE"){
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, EXPIRED CARD, Account number ending in, 1 2 3 4, Default payment account, expired, Fees: $0.00 Residential | 0% Business'")
        } else {
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, EXPIRED CARD, Account number ending in, 1 2 3 4, Default payment account, expired, $0.00 Convenience Fee'")
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
        selectTab(tabName: "Bill")
        
        app.buttons["My Wallet"].tap()
        
        if appName.contains("BGE"){
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, TEST NICKNAME, Account number ending in, 1 2 3 4, Default payment account, Fees: $0.00 Residential | 0% Business'")
            let expiredCardButton = app.tables.cells.buttons.element(matching: predicate)
            expiredCardButton.tap()
            elementsQuery.buttons["Tool tip"].tap()
            XCTAssert(elementsQuery.staticTexts["Your security code is usually a 3 or 4 digit number found on your card."].exists)
        } else {
            predicate = NSPredicate(format: "label CONTAINS 'Saved credit card button, TEST NICKNAME, Account number ending in, 1 2 3 4, Default payment account, $0.00 Convenience Fee'")
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
