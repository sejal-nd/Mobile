//
//  HomeBillCardUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest


class HomeBillCardUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        launchApp()
    }
    
    func testNoDefaultPaymentSetWithBill() {
        doLogin(username: "billCardNoDefaultPayment")

        checkExistenceOfElement(.staticText, "$200.00")
        
        tapButton(buttonText: "Set a default payment method")
        
        XCTAssertTrue(app.navigationBars["My Wallet"].waitForExistence(timeout: 3))
        tapButton(buttonText: "Back")
        
        let slideToPayControl = app.otherElements["Pay full bill now"]
        XCTAssertFalse(slideToPayControl.exists, "Slide to pay should be disabled when no default payment method")
    }
    
    func testDefaultPaymentSetWithBill() {
        doLogin(username: "billCardWithDefaultPayment")

        XCTAssertFalse(buttonElement(withText: "Set a default payment method").exists, "Set payment method button should be hidden when one is already set")

        checkExistenceOfElements([
            (.staticText, "$5,000.00"),
            (.button, "Bank account, Account ending in 1234")
        ])

        XCTAssertTrue(app.scrollViews.otherElements["Pay full bill now"].isEnabled, "Slide to pay should be enabled")
    }
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")

        tapButton(buttonText: "Thank you for scheduling your $82.00 payment")
        XCTAssertTrue(app.navigationBars["Bill & Payment Activity"].waitForExistence(timeout: 3))
    }
    
    func testThankYouForPayment() {
        doLogin(username: "thankYouForPayment")

        checkExistenceOfElements([
            (.staticText, "Thank you for your payment"),
            (.staticText, "$200.00")
        ])
    }
    
    func testPastDue() {
        doLogin(username: "pastDue")

        checkExistenceOfElements([
            (.staticText, "$140.00 of the total is due immediately."),
            (.staticText, "$200.00"),
            (.staticText, "Total Amount Due")
        ])
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")

        checkExistenceOfElements([
            (.staticText, "$100.00 of the total must be paid immediately to avoid shutoff."),
            (.staticText, "$350.00"),
            (.staticText, "Total Amount Due")
        ])
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")

        let paymentMessage = appOpCo == .bge
            ? "You have processing payments"
            : "You have pending payments"

        checkExistenceOfElements([
            (.staticText, paymentMessage),
            (.staticText, "$100.00")
        ])
    }
    
    func testHiddenSlideToPay(){
        doLogin(username: "billCardWithExpiredDefaultPayment")
        
        let slideToPayControl = app.otherElements["Pay full bill now"]
        XCTAssertFalse(slideToPayControl.exists, "Slider should be disabled when card is expired")
    }
}
