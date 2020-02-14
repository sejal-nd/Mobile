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

        checkExistenceOfElements([
            (.staticText, "Account number: 1234567890"),
            (.staticText, "Street address: 573 Elm Street"),
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

        let nextButton = buttonElement(withText: "Continue")
        sleep(1) // Button becomes enabled asynchronously
        XCTAssertTrue(nextButton.isEnabled, "Next button should be immediately enabled in this scenario")

        tapButton(buttonText: "Bank account, Test Bank, Account number ending in, 1234")
        checkExistenceOfElement(.staticText, "Select Payment Method")
        app.otherElements["Back"].tap()

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

        if appOpCo == .bge {
            tapButton(buttonText: "01/01/2019")
        } else {
            tapButton(buttonText: "01/11/2019")
        }
        checkExistenceOfElement(.navigationBar, "Select Payment Date")
        tapButton(buttonText: "Back")
    }

    func testPaymentusActionSheetEmptyWallet() {
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        
        sleep(3)
        
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
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Bank account, Test Bank, Account number ending in, 1234")
        checkExistenceOfElement(.staticText, "Select Payment Method")

        sleep(3)
        
        let tableView = app.tables.matching(identifier: "miniWalletTableView")
        let cell = tableView.cells.element(matching: .cell, identifier: "Add Bank Account")
        cell.tap()
        
        sleep(2)
        
        checkExistenceOfElements([
            (.sheet, "Add Bank Account"),
            (.button, "Save to My Wallet"),
            (.button, "Don't Save to My Wallet"),
            (.button, "Cancel")
        ])

        tapButton(buttonText: "Cancel")
        
        tapButton(buttonText: "Bank account, Test Bank, Account number ending in, 1234")
        
        let cell2 = tableView.cells.element(matching: .cell, identifier: "Add Credit/Debit Card")
        cell2.tap()
        
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
        let nextButton = buttonElement(withText: "Continue")
        sleep(1) // Button becomes enabled asynchronously
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

        XCTAssertTrue(app.scrollViews.otherElements["Bank account, Test Bank, Account number ending in, 1234"].exists)

        checkExistenceOfElements([
            (.navigationBar, "Review Payment"),
            (.staticText, "Payment Method"),
            (.staticText, "Total Amount Due"),
            (.staticText, "$5,000.00"),
            (.staticText, "Due Date"),
            (.staticText, "Payment Date"),
            (.staticText, "Total Payment"),
            (.staticText, "$5,000.00")
        ])
        
        if appOpCo == .bge {
            checkExistenceOfElement(.staticText, "01/01/2019")
        } else {
            checkExistenceOfElement(.staticText, "01/11/2019")
        }
        
        let submitButton = app.buttons["Submit Payment"]
        
        let termsButton = app.scrollViews.otherElements.buttons.element(boundBy: 0)
        XCTAssertTrue(termsButton.exists)
        termsButton.tap()
        
        checkExistenceOfElement(.staticText, "Terms and Conditions")
        
        tapButton(buttonText: "Close")
        
        let termsCheckbox = XCUIApplication().otherElements[String(format: NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:, Checkbox, Unchecked", comment: ""), appOpCo.rawValue)]
        XCTAssertFalse(submitButton.isEnabled, "ComEd/PECO needs to agree to terms first so submit should be initially disabled")
        termsCheckbox.tap()
        
        XCTAssertTrue(submitButton.isEnabled)
        
        submitButton.tap()

        checkExistenceOfElements([
            (.staticText, "Thank you for your payment"),
            (.staticText, "Confirmation Number"),
            (.staticText, "Payment Date"),
            (.staticText, "Amount Paid"),
            (.staticText, "$5,000.00"),
        ])
        
        if appOpCo == .bge {
            checkExistenceOfElement(.staticText, "01/01/2019")
        } else {
            checkExistenceOfElement(.staticText, "01/11/2019")
        }
        
        checkExistenceOfElement(.staticText, "A confirmation email will be sent to you shortly.")

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

        let nextButton = buttonElement(withText: "Continue")
        sleep(1) // Button becomes enabled asynchronously
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()

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

        let submitButton = element(ofType: .button, withText: "Submit")
        
        let overpayCheckbox = XCUIApplication().otherElements[String(format: NSLocalizedString("Yes, I acknowledge I am scheduling a payment for more than is currently due on my account., Checkbox, Unchecked", comment: ""), appOpCo.rawValue)]
        XCTAssertFalse(submitButton.isEnabled, "ComEd/PECO needs to agree to terms first so submit should be initially disabled")
        overpayCheckbox.tap()
        
        let termsCheckbox = XCUIApplication().otherElements[String(format: NSLocalizedString("Yes, I have read, understand, and agree to the terms and conditions provided below:, Checkbox, Unchecked", comment: ""), appOpCo.rawValue)]
        XCTAssertFalse(submitButton.isEnabled, "Needs to agree to terms first so submit should be initially disabled")
        termsCheckbox.tap()

        XCTAssertTrue(submitButton.isEnabled)
        submitButton.tap()

        checkExistenceOfElement(.staticText, "A confirmation email will be sent to you shortly.")
    }

    func testComEdPECOTempPaymentusBankPayment() {
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add bank account")

        // TODO - Add bank, Make Payment
    }

    func testComEdPECOTempPaymentusCardPayment() {
        doLogin(username: "billCardNoDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        tapButton(buttonText: "Add credit/debit card")

        // TODO - Add card, Make Payment
    }
}
