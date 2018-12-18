//
//  PaymentUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class PaymentUITests: ExelonUITestCase {
   
    // MARK: MakePaymentViewController Layout Tests
    
    func testLayoutNoPaymentMethods() {
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")

        checkExistenceOfElement(.navigationBar, "Make a Payment")
        XCTAssertFalse(app.navigationBars.buttons["Next"].isEnabled, "Next button should be disabed initially")

        checkExistenceOfElements([
            (.staticText, "Account number: 1234567890, Street address: 573 Elm Street"),
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "Due Date"),
            (.button, "Add bank account"),
            (.button, "Add credit/debit card")
        ])
        
        if appOpCo == .bge {
            checkExistenceOfElements([
                (.staticText, "We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.")
            ])
        } else {
            checkExistenceOfElements([
                (.staticText, "All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation.")
            ])
        }
    }
    
    func testLayoutExistingWalletItems() {
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        
        let nextButton = buttonElement(withText: "Next")
        sleep(1) // Button becomes enabled asynchronously
        XCTAssertTrue(nextButton.isEnabled, "Next button should be immediately enabled in this scenario")
        checkExistenceOfElement(.staticText, "Payment Method")
        
        tapButton(buttonText: "Bank account, Test Nickname, Account number ending in, 1234")
        checkExistenceOfElement(.navigationBar, "Select Payment Method")
        tapButton(buttonText: "Back")

        checkExistenceOfElements([
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "No convenience fee will be applied."),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date"),
            (.textField, "Payment Amount, required")
        ])

        let paymentAmountTextField = element(ofType: .textField, withText: "Payment Amount, required")
        XCTAssertEqual(paymentAmountTextField.value as? String, "$200.00", "Payment amount value entry should default to the amount due")

        let dateText = dateString(from: Date())

        tapButton(buttonText: dateText)
        checkExistenceOfElement(.navigationBar, "Select Payment Date")
        tapButton(buttonText: "Back")
    }
    
    func testInlineBankLayoutBGE() {
        guard appOpCo == .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")

        tapButton(buttonText: "Add bank account")

        XCTAssertTrue(app.scrollViews.otherElements["Checking, option 1 of 2 , selected"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.scrollViews.otherElements["Savings, option 2 of 2 "].exists)

        checkExistenceOfElements([
            (.textField, "Bank Account Holder Name, required"),
            (.textField, "Routing Number, required")
        ])

        let tooltipQuery = app.scrollViews.otherElements.buttons.matching(identifier: "Tool tip")

        let routingTooltip = tooltipQuery.element(boundBy: 0)
        XCTAssertTrue(routingTooltip.exists)
        routingTooltip.tap()

        checkExistenceOfElements([
            (.image, "routing_number_info"),
            (.staticText, "Routing Number"),
            (.staticText, "This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.")
        ])
        tapButton(buttonText: "Close")

        let accountTooltip = tooltipQuery.element(boundBy: 1)
        XCTAssertTrue(accountTooltip.waitForExistence(timeout: 2))
        accountTooltip.tap()

        checkExistenceOfElements([
            (.image, "account_number_info"),
            (.staticText, "Account Number"),
            (.staticText, "This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.")
        ])
        tapButton(buttonText: "Close")

        checkExistenceOfElements([
            (.textField, "Account Number, required"),
            (.textField, "Confirm Account Number, required"),
            (.textField, "Nickname, required"),
            (.staticText, "Set this payment method as default to easily pay from the Home and Bill screens."),
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "No convenience fee will be applied."),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date")
        ])

        let confirmAccountField = element(ofType: .textField, withText: "Confirm Account Number, required")
        XCTAssertFalse(confirmAccountField.isEnabled)

        let defaultAccountSwitch = element(ofType: .switch, withText: "Default payment method")
        XCTAssertEqual(defaultAccountSwitch.value as? String, "0", "Default Payment Method switch should be OFF by default")

        let paymentAmountTextField = element(ofType: .textField, withText: "Payment Amount, required")
        XCTAssertEqual(paymentAmountTextField.value as? String, "$200.00", "Payment amount value entry should default to the amount due")

        tapButton(buttonText: dateString(from: Date()))
        XCTAssertTrue(app.navigationBars["Select Payment Date"].waitForExistence(timeout: 2))
    }
    
    func testInlineCardLayoutBGE() {
        guard appOpCo == .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add credit/debit card")
        
        checkExistenceOfElements([
            (.textField, "Name on Card, required"),
            (.textField, "Card Number, required"),
            (.button, "Take a photo to scan credit card number"),
            (.staticText, "Expiration Date"),
            (.textField, "Month, two digits"),
            (.textField, "Year, four digits"),
            (.textField, "CVV, required"),
            (.textField, "Zip Code, required"),
            (.textField, "Nickname, required"),
            (.staticText, "Save to My Wallet"),
            (.staticText, "Set this payment method as default to easily pay from the Home and Bill screens."),
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "A convenience fee will be applied to this payment. Residential accounts: $0.00. Business accounts: 0%."),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date")
        ])
        
        let saveToWalletSwitch = element(ofType: .switch, withText: "Save to my wallet")
        XCTAssertEqual(saveToWalletSwitch.value as? String, "1", "Save to My Wallet switch should be ON by default")
        
        let defaultAccountSwitch = element(ofType: .switch, withText: "Default payment method")
        XCTAssertEqual(defaultAccountSwitch.value as? String, "0", "Default Payment Method switch should be OFF by default")
        
        let paymentAmountTextField = element(ofType: .textField, withText: "Payment Amount, required")
        XCTAssertEqual(paymentAmountTextField.value as? String, "$200.00", "Payment amount value entry should default to the amount due")
        
        tapButton(buttonText: "Tool tip")
        checkExistenceOfElements([
            (.image, "cvv_info"),
            (.staticText, "Your security code is usually a 3 or 4 digit number found on your card.")
            ])
        tapButton(buttonText: "Close")
        
        tapButton(buttonText: dateString(from: Date()))
        checkExistenceOfElement(.navigationBar, "Select Payment Date")
    }
    
    func testPaymentusActionSheetEmptyWallet() {
        guard appOpCo != .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add bank account")
        
        checkExistenceOfElements([
            (.sheet, "Add Bank Account"),
            (.button, "Save to My Wallet"),
            (.button, "Don't Save to My Wallet"),
            (.button, "Cancel")
        ])
        
        tapButton(buttonText: "Cancel")
        tapButton(buttonText: "Add credit/debit card")
        
        checkExistenceOfElements([
            (.sheet, "Add Credit/Debit Card"),
            (.button, "Save to My Wallet"),
            (.button, "Don't Save to My Wallet"),
            (.button, "Cancel")
        ])
    }
    
    func testPaymentusActionSheetMiniWallet() {
        guard appOpCo != .bge else {
            return
        }
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Bank account, Test Nickname, Account number ending in, 1234")
        checkExistenceOfElement(.navigationBar, "Select Payment Method")
        
        tapButton(buttonText: "Add Bank Account")
        checkExistenceOfElements([
            (.sheet, "Add Bank Account"),
            (.button, "Save to My Wallet"),
            (.button, "Don't Save to My Wallet"),
            (.button, "Cancel")
        ])
        
        tapButton(buttonText: "Cancel")
        tapButton(buttonText: "Add Credit/Debit Card")
        checkExistenceOfElements([
            (.sheet, "Add Credit/Debit Card"),
            (.button, "Save to My Wallet"),
            (.button, "Don't Save to My Wallet"),
            (.button, "Cancel")
        ])
    }
    
    // MARK: Schedule Payments
    
    func testMakePaymentExistingWalletItem() {
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        let nextButton = buttonElement(withText: "Next")
        sleep(1) // Button becomes enabled asynchronously
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        let dateText = dateString(from: Date())

        XCTAssertTrue(app.scrollViews.otherElements["Bank account, Test Nickname, Account number ending in, 1234"].exists)

        checkExistenceOfElements([
            (.navigationBar, "Review Payment"),
            (.staticText, "Payment Method"),
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date"),
            (.staticText, "Total Payment"),
            (.staticText, "$200.00"),
            (.staticText, dateText)
        ])
        
        let submitButton = app.navigationBars.buttons["Submit"]
        if appOpCo == .bge {
            XCTAssertTrue(submitButton.isEnabled, "BGE does not need to agree to terms so submit should be immediately enabled")
        } else {
            let termsButton = app.scrollViews.otherElements.buttons.element(boundBy: 0)
            XCTAssertTrue(termsButton.exists)
            termsButton.tap()

            checkExistenceOfElement(.staticText, "Terms and Conditions")

            tapButton(buttonText: "Close")
        
            let termsSwitch = element(ofType: .switch, withText: "Yes, I have read, understand, and agree to the terms and conditions provided below:")
            XCTAssertEqual(termsSwitch.value as? String, "0", "Terms switch should be OFF by default")
            
            XCTAssertFalse(submitButton.isEnabled, "ComEd/PECO needs to agree to terms first so submit should be initially disabled")
            termsSwitch.tap()
            XCTAssertTrue(submitButton.isEnabled)
        }
        submitButton.tap()

        let thankyouText = appOpCo == .bge
            ? "Thank you for your payment."
            : "Thank you for your payment. A confirmation email will be sent to you shortly."

        checkExistenceOfElements([
            (.staticText, thankyouText),
            (.staticText, "Payment Confirmation"),
            (.staticText, "Payment Date"),
            (.staticText, dateText),
            (.staticText, "Amount Paid"),
            (.staticText, "$200.00"),
        ])

        tapButton(buttonText: "Close")
        
        XCTAssertTrue(app.tabBars.buttons["Bill"].waitForExistence(timeout: 2), "Should be back on the bill tab after closing")
    }
    
    func testMakePaymentBGEOverpaying() {
        guard appOpCo == .bge else {
            return
        }
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")

        let paymentAmountTextField = element(ofType: .textField, withText: "Payment Amount, required")
        paymentAmountTextField.clearAndEnterText("30000")

        app.navigationBars.buttons["Next"].tap()

        checkExistenceOfElements([
            (.navigationBar, "Review Payment"),
            (.staticText, "You are scheduling a payment that may result in overpaying your total amount due."),
            (.staticText, "Total Amount Due"),
            (.staticText, "$200.00"),
            (.staticText, "Due Date"),
            (.staticText, "Overpaying"),
            (.staticText, "$100.00"),
            (.staticText, "Payment Date"),
            (.staticText, dateString(from: Date())),
            (.staticText, "Payment Amount"),
            (.staticText, "$300.00"),
        ])

        let overpaySwitch = element(ofType: .switch, withText: "Yes, I acknowledge I am scheduling a payment for more than is currently due on my account.")
        XCTAssertEqual(overpaySwitch.value as? String, "0", "Overpay switch should be OFF by default")

        let submitButton = app.navigationBars.buttons["Submit"]
        XCTAssertFalse(submitButton.isEnabled, "Submit should be disabled until overpay switch is toggled")
        overpaySwitch.tap()
        XCTAssertTrue(submitButton.isEnabled)
        submitButton.tap()

        checkExistenceOfElement(.staticText, "Payment Confirmation")
    }
    
    func testBGEInlineBankPayment() {
        guard appOpCo == .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add bank account")

        let textFields = app.scrollViews.otherElements.textFields
        let nextButton = app.navigationBars.buttons["Next"]
        XCTAssertFalse(nextButton.isEnabled)

        textFields["Bank Account Holder Name, required"].clearAndEnterText("Testy McTesterson")
        textFields["Routing Number, required"].clearAndEnterText("022000046")
        textFields["Account Number, required"].clearAndEnterText("1234567890")
        textFields["Confirm Account Number, required"].clearAndEnterText("1234567890")
        textFields["Nickname, required"].clearAndEnterText("Test nickname")

        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        checkExistenceOfElement(.navigationBar, "Review Payment")
    }
    
    func testBGEInlineCardPayment() {
        guard appOpCo == .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add credit/debit card")

        let textFields = app.scrollViews.otherElements.textFields
        let nextButton = app.navigationBars.buttons["Next"]
        XCTAssertFalse(nextButton.isEnabled)

        textFields["Name on Card, required"].clearAndEnterText("Testy McTesterson")
        textFields["Card Number, required"].clearAndEnterText("5444009999222205")
        textFields["Month, two digits"].clearAndEnterText("08")
        textFields["Year, four digits"].clearAndEnterText("3000")
        textFields["CVV, required"].clearAndEnterText("123")
        textFields["Zip Code, required"].clearAndEnterText("10007")
        textFields["Nickname, required"].clearAndEnterText("Test nickname")

        XCTAssert(nextButton.isEnabled)
        nextButton.tap()

        checkExistenceOfElement(.navigationBar, "Review Payment")

        let submitButton = element(ofType: .button, withText: "Submit")
        let bgeCardSwitch = element(ofType: .switch, withText: "I have read and accept the Terms and Conditions below & E-Sign Disclosure and Consent Notice. Please review and retain a copy for your records.")
        XCTAssertEqual(bgeCardSwitch.value as? String, "0", "Switch should be OFF by default")
        XCTAssertFalse(submitButton.isEnabled)

        bgeCardSwitch.tap()
        XCTAssert(submitButton.isEnabled)
        submitButton.tap()

        checkExistenceOfElement(.staticText, "Payment Confirmation")
    }
    
    func testComEdPECOTempPaymentusBankPayment() {
        guard appOpCo != .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add bank account")
        
        // TODO - Add bank, Make Payment
    }
    
    func testComEdPECOTempPaymentusCardPayment() {
        guard appOpCo != .bge else {
            return
        }
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add credit/debit card")
        
        // TODO - Add card, Make Payment
    }
}

