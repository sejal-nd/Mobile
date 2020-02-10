//
//  BillUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class BillUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        launchApp()
    }
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")
        selectTab(tabName: "Bill")

        let buttonText = "Thank you for scheduling your $82.00 payment for 01/01/2019"
        checkExistenceOfElement(.button, buttonText)
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")
        selectTab(tabName: "Bill")

        let buttonText = "Thank you for $200.00 payment on 01/11/2019"
        checkExistenceOfElement(.button, buttonText)
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")
        selectTab(tabName: "Bill")

        checkExistenceOfElements([
            (.staticText, "$140.00 of the total is due immediately."),
            (.staticText, "$200.00"),
            (.staticText, "Past Due Amount"),
            (.staticText, "Due Immediately")
        ])
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")
        selectTab(tabName: "Bill")
        
        checkExistenceOfElements([
            (.staticText, "$100.00 of the total must be paid immediately to avoid shut-off."),
            (.staticText, "$350.00"),
            (.staticText, "Past Due Amount"),
            (.staticText, "Due Immediately")
            ])
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")
        selectTab(tabName: "Bill")

        let paymentText = appOpCo == .bge
            ? "Payments Processing"
            : "Pending Payments"

        checkExistenceOfElements([
            (.staticText, "-$100.00"),
            (.staticText, paymentText)
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
    }
    
}
