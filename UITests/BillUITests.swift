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
        checkExistenceOfElement(.button, buttonText)
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")
        selectTab(tabName: "Bill")

        let buttonText = "Thank you for $200.00 payment on \(dateString(from: Date()))"
        checkExistenceOfElement(.button, buttonText)
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")
        selectTab(tabName: "Bill")

        checkExistenceOfElements([
            (.staticText, "Amount Past Due"),
            (.staticText, "Total Amount Due Immediately"),
            (.staticText, "$200.00"),
            (.staticText, "Due Immediately")
        ])
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")
        selectTab(tabName: "Bill")
        
        if appOpCo == .bge {
            checkExistenceOfElements([
                (.staticText, "Amount Due to Avoid Service Interruption"),
                (.staticText, "$200.00")
            ])
        } else {
            checkExistenceOfElements([
                (.staticText, "Payment due to avoid shut-off is $200.00 due immediately."),
                (.staticText, "Amount Due to Avoid shut-off"),
                (.staticText, "Due Immediately")
            ])
        }
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")
        selectTab(tabName: "Bill")

        let paymentText = appOpCo == .bge
            ? "Payment Processing"
            : "Pending Payment"

        checkExistenceOfElements([
            (.staticText, "-$200.00"),
            (.staticText, paymentText)
        ])
    }
    
    func testMaintModeBill() {
        doLogin(username: "maintNotHome")
        selectTab(tabName: "Bill")

        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Billing is currently unavailable due to maintenance.")
        ])
    }
    
    func testExpiredCc() {
        let alertsQuery = app.alerts
        doLogin(username: "billCardWithExpiredDefaultPayment")
        selectTab(tabName: "Bill")
        
        //Check for expired card warning
        tapButton(buttonText: "My Wallet")
        let alert = alertsQuery.staticTexts["Please update your Wallet as one or more of your saved payment methods have expired."]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        let okButton = alertsQuery.buttons["OK"]
        okButton.tap()
        
        // TODO - Remove this `if` when BGE goes to Paymentus
        if appOpCo == .bge {
            let expiredCardCell = app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Saved credit card, EXPIRED CARD, Account number ending in, 1 2 3 4, Default payment method, expired'"))
            let editButton = expiredCardCell.buttons["Edit payment method"]
            
            editButton.tap()
            
            checkExistenceOfElement(.staticText, "Expired")
            let cancelButton = app.navigationBars["Edit Card"].buttons["Cancel"]
            cancelButton.tap()
        }
    }
    
    // TODO - Remove this test when BGE goes to Paymentus
    func testCvvText() {
        if appOpCo == .bge {
            let elementsQuery = app.scrollViews.otherElements
            doLogin(username: "billCardWithDefaultCcPayment")
            selectTab(tabName: "Bill")
            
            tapButton(buttonText: "My Wallet")
            
            let cell = app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Saved credit card, TEST NICKNAME, Account number ending in, 1 2 3 4, Default payment method'"))
            let editButton = cell.buttons["Edit payment method"]
            editButton.tap()
            elementsQuery.buttons["Tool tip"].tap()
            checkExistenceOfElement(.staticText, "Your security code is usually a 3 or 4 digit number found on your card.")
        }
    }
}
