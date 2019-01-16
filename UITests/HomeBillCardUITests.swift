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

        checkExistenceOfElement(.staticText, "$200.00")
        
        tapButton(buttonText: "Set a default payment method")
        
        XCTAssertTrue(app.navigationBars["My Wallet"].waitForExistence(timeout: 3))
        tapButton(buttonText: "Back")
        
        let slideToPayControl = app.scrollViews.otherElements["Slide to pay today"]
        XCTAssertFalse(slideToPayControl.isEnabled, "Slide to pay should be disabled when no default payment method")
    }
    
    func testDefaultPaymentSetWithBill() {
        doLogin(username: "billCardWithDefaultPayment")

        XCTAssertFalse(buttonElement(withText: "Set a default payment method").exists, "Set payment method button should be hidden when one is already set")

        checkExistenceOfElements([
            (.staticText, "$200.00"),
            (.button, "Bank account, Account ending in 1234")
        ])

        XCTAssertTrue(app.scrollViews.otherElements["Slide to pay today"].isEnabled, "Slide to pay should be enabled")
    }
    
    func testScheduledPayment() {
        doLogin(username: "scheduledPayment")

        tapButton(buttonText: "Thank you for scheduling your $82.00 payment")
        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 3))
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
            (.staticText, "Your bill is past due."),
            (.staticText, "$200.00"),
            (.staticText, "Total amount due immediately")
        ])
    }
    
    func testAvoidShutoff() {
        doLogin(username: "avoidShutoff")

        let dueMessage = appOpCo == .bge
            ? "$200.00 is due in 10 days to avoid service interruption."
            : "$200.00 is due immediately to avoid shutoff."

        checkExistenceOfElements([
            (.staticText, dueMessage),
            (.staticText, "$350.00"),
            (.staticText, "Total amount due in 10 days")
        ])
    }
    
    func testPaymentPending() {
        doLogin(username: "paymentPending")

        let paymentMessage = appOpCo == .bge
            ? "Your payment is processing"
            : "Your payment is pending"

        checkExistenceOfElements([
            (.staticText, paymentMessage),
            (.staticText, "$200.00")
        ])
    }
    
    func testMaintModeHomeBillCard() {
        doLogin(username: "maintNotHome")
        
        checkExistenceOfElement(.staticText, "Billing is currently unavailable due to maintenance.")
    }
    
    func testMaintModeHome() {
        doLogin(username: "maintAllTabs")

        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Home is currently unavailable due to maintenance.")
        ])
    }
    
    func testExpiredSlideToPay(){
        doLogin(username: "billCardWithExpiredDefaultPayment")
        
        //Assert slider is disabled since card is expired
        let slideToPayControl = app.scrollViews.otherElements["Slide to pay today"]
        XCTAssertTrue(slideToPayControl.waitForExistence(timeout: 5))
        XCTAssertFalse(slideToPayControl.isEnabled, "Slider should be disabled when card is expired")
    }
}
