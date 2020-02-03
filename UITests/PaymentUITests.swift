//
//  PaymentUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest


class PaymentUITests: ExelonUITestCase {

    override func setUp() {
        super.setUp()
        launchApp()
    }

    
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

        checkExistenceOfElement(.staticText, "All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation.")
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
            (.staticText, "$5,000.00"),
            (.staticText, "No convenience fee will be applied."),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date"),
            (.textField, "Payment Amount, required")
        ])

        let paymentAmountTextField = element(ofType: .textField, withText: "Payment Amount, required")
        XCTAssertEqual(paymentAmountTextField.value as? String, "$5,000.00", "Payment amount value entry should default to the amount due")

        tapButton(buttonText: "01/01/2019")
        checkExistenceOfElement(.navigationBar, "Select Payment Date")
        tapButton(buttonText: "Back")
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

        XCTAssertTrue(app.scrollViews.otherElements["Bank account, Test Nickname, Account number ending in, 1234"].exists)

        checkExistenceOfElements([
            (.navigationBar, "Review Payment"),
            (.staticText, "Payment Method"),
            (.staticText, "Total Amount Due"),
            (.staticText, "$5,000.00"),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date"),
            (.staticText, "Total Payment"),
            (.staticText, "$5,000.00"),
            (.staticText, "01/01/2019")
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
            (.staticText, "01/01/2019"),
            (.staticText, "Amount Paid"),
            (.staticText, "$5,000.00"),
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
        paymentAmountTextField.clearAndEnterText("510000")

        app.navigationBars.buttons["Next"].tap()

        checkExistenceOfElements([
            (.navigationBar, "Review Payment"),
            (.staticText, "You are scheduling a payment that may result in overpaying your total amount due."),
            (.staticText, "Total Amount Due"),
            (.staticText, "$5,000.00"),
            (.staticText, "Due Date"),
            (.staticText, "Overpaying"),
            (.staticText, "$100.00"),
            (.staticText, "Payment Date"),
            (.staticText, "01/01/2019"),
            (.staticText, "Payment Amount"),
            (.staticText, "$5,100.00"),
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
