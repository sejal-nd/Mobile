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
        
        XCTAssert(app.navigationBars["Make a Payment"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.navigationBars.buttons["Next"].isEnabled, "Next button should be disabed initially")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Account number: 1234567890, Street address: 573 Elm Street"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["No convenience fee will be applied."].exists)
        XCTAssert(app.scrollViews.otherElements.buttons["Add bank account"].exists)
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["A convenience fee will be applied to this payment. Residential accounts: $0.00. Business accounts: 0%."].exists)
            let pred = NSPredicate(format: "label like %@", "We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.")
            XCTAssert(app.scrollViews.otherElements.staticTexts.element(matching: pred).exists)
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["A $0.00 convenience fee will be applied by Bill Matrix, our payment partner."].exists)
            let pred = NSPredicate(format: "label like %@", "Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.")
            XCTAssert(app.scrollViews.otherElements.staticTexts.element(matching: pred).exists)
        }
        XCTAssert(app.scrollViews.otherElements.buttons["Add credit/debit card"].exists)
    }
    
    func testLayoutExistingWalletItems() {
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        
        let nextButton = app.navigationBars.buttons["Next"]
        XCTAssert(nextButton.waitForExistence(timeout: 2))
        XCTAssert(nextButton.isEnabled, "Next button should be immediately enabled in this scenario")
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Account"].exists)
        
        let paymentAccountButton = app.scrollViews.otherElements.buttons["Bank account, Test Nickname, Account number ending in, 1234"]
        XCTAssert(paymentAccountButton.exists)
        paymentAccountButton.tap()
        XCTAssert(app.navigationBars["Select Payment Account"].waitForExistence(timeout: 2))
        app.navigationBars.buttons["Back"].tap()
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].waitForExistence(timeout: 2))
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["No convenience fee will be applied."].exists)
        let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
        XCTAssert(paymentAmountTextField.exists)
        if let textFieldValue = paymentAmountTextField.value as? String {
            XCTAssert(textFieldValue == "$200.00", "Payment amount value entry should default to the amount due")
        } else {
            XCTFail("Could not get paymentAmountTextField value")
        }
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: Date())
        let paymentDateButton = app.scrollViews.otherElements.buttons[dateString]
        XCTAssert(paymentDateButton.exists)
        paymentDateButton.tap()
        XCTAssert(app.navigationBars["Select Payment Date"].waitForExistence(timeout: 2))
        app.navigationBars.buttons["Back"].tap()
        
        if !appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.images["ic_billmatrix"].waitForExistence(timeout: 2))
            
            let privacyPolicyButton = app.scrollViews.otherElements.buttons["Privacy Policy"]
            XCTAssert(privacyPolicyButton.exists)
            privacyPolicyButton.tap()
            XCTAssert(app.staticTexts["Privacy Policy"].waitForExistence(timeout: 2))
        }
    }
    
    func testInlineBankLayoutBGE() {
        if appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addBankButton = app.scrollViews.otherElements.buttons["Add bank account"]
            XCTAssert(addBankButton.waitForExistence(timeout: 3))
            addBankButton.tap()
            
            XCTAssert(app.scrollViews.otherElements["Checking, option 1 of 2 , selected"].waitForExistence(timeout: 3))
            XCTAssert(app.scrollViews.otherElements["Savings, option 2 of 2 "].exists)
            
            XCTAssert(app.scrollViews.otherElements.textFields["Bank Account Holder Name, required"].exists)
            XCTAssert(app.scrollViews.otherElements.textFields["Routing Number, required"].exists)
            
            let tooltipQuery = app.scrollViews.otherElements.buttons.matching(identifier: "Tool tip")
            
            let routingTooltip = tooltipQuery.element(boundBy: 0)
            XCTAssert(routingTooltip.exists)
            routingTooltip.tap()
            XCTAssert(app.staticTexts["Routing Number"].waitForExistence(timeout: 2))
            var closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            let accountTooltip = tooltipQuery.element(boundBy: 1)
            XCTAssert(accountTooltip.waitForExistence(timeout: 2))
            accountTooltip.tap()
            XCTAssert(app.staticTexts["Account Number"].waitForExistence(timeout: 2))
            closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            XCTAssert(app.scrollViews.otherElements.textFields["Account Number, required"].waitForExistence(timeout: 2))
            let confirmAccountField = app.scrollViews.otherElements.textFields["Confirm Account Number, required"]
            XCTAssert(confirmAccountField.exists)
            XCTAssertFalse(confirmAccountField.isEnabled)
            XCTAssert(app.scrollViews.otherElements.textFields["Nickname, required"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Set this payment account as default to easily pay from the Home and Bill screens."].exists)
            let defaultAccountSwitch = app.scrollViews.otherElements.switches["Default payment account"]
            if let switchValueStr = defaultAccountSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Default Payment Account switch should be OFF by default")
            } else {
                XCTFail("Could not get defaultAccountSwitch value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["No convenience fee will be applied."].exists)
            let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
            XCTAssert(paymentAmountTextField.exists)
            if let textFieldValue = paymentAmountTextField.value as? String {
                XCTAssert(textFieldValue == "$200.00", "Payment amount value entry should default to the amount due")
            } else {
                XCTFail("Could not get paymentAmountTextField value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
                        let dateString = dateFormatter.string(from: Date())
            let paymentDateButton = app.scrollViews.otherElements.buttons[dateString]
            XCTAssert(paymentDateButton.exists)
            paymentDateButton.tap()
            XCTAssert(app.navigationBars["Select Payment Date"].waitForExistence(timeout: 2))
        }
    }
    
    func testInlineBankLayoutComEdPECO() {
        if !appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addBankButton = app.scrollViews.otherElements.buttons["Add bank account"]
            XCTAssert(addBankButton.waitForExistence(timeout: 3))
            addBankButton.tap()
            
            XCTAssert(app.scrollViews.otherElements.textFields["Routing Number, required"].waitForExistence(timeout: 3))
            XCTAssert(app.scrollViews.otherElements.textFields["Account Number, required"].exists)
            
            let tooltipQuery = app.scrollViews.otherElements.buttons.matching(identifier: "Tool tip")
            
            let routingTooltip = tooltipQuery.element(boundBy: 0)
            XCTAssert(routingTooltip.exists)
            routingTooltip.tap()
            XCTAssert(app.staticTexts["Routing Number"].waitForExistence(timeout: 2))
            var closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            let accountTooltip = tooltipQuery.element(boundBy: 1)
            XCTAssert(accountTooltip.waitForExistence(timeout: 2))
            accountTooltip.tap()
            XCTAssert(app.staticTexts["Account Number"].waitForExistence(timeout: 2))
            closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            let confirmAccountField = app.scrollViews.otherElements.textFields["Confirm Account Number, required"]
            XCTAssert(confirmAccountField.exists)
            XCTAssertFalse(confirmAccountField.isEnabled)
            
            let saveToWalletSwitch = app.scrollViews.otherElements.switches["Save to my wallet"]
            XCTAssert(saveToWalletSwitch.exists)
            if let switchValueStr = saveToWalletSwitch.value as? String {
                XCTAssert(switchValueStr == "1", "Save to My Wallet switch should be ON by default")
            } else {
                XCTFail("Could not get saveToWalletSwitch value")
            }
            XCTAssert(app.scrollViews.otherElements.staticTexts["Save to My Wallet"].exists)
            
            XCTAssert(app.scrollViews.otherElements.textFields["Nickname (Optional)"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Set this payment account as default to easily pay from the Home and Bill screens."].exists)
            let defaultAccountSwitch = app.scrollViews.otherElements.switches["Default payment account"]
            if let switchValueStr = defaultAccountSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Default Payment Account switch should be OFF by default")
            } else {
                XCTFail("Could not get defaultAccountSwitch value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["No convenience fee will be applied."].exists)
            let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
            XCTAssert(paymentAmountTextField.exists)
            if let textFieldValue = paymentAmountTextField.value as? String {
                XCTAssert(textFieldValue == "$200.00", "Payment amount value entry should default to the amount due")
            } else {
                XCTFail("Could not get paymentAmountTextField value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: Date())
            let paymentDateButton = app.scrollViews.otherElements.buttons[dateString]
            XCTAssert(paymentDateButton.exists)
            paymentDateButton.tap()
            XCTAssert(app.navigationBars["Select Payment Date"].waitForExistence(timeout: 2))
            app.navigationBars.buttons["Back"].tap()
            
            XCTAssert(app.scrollViews.otherElements.images["ic_billmatrix"].waitForExistence(timeout: 2))
            
            let privacyPolicyButton = app.scrollViews.otherElements.buttons["Privacy Policy"]
            XCTAssert(privacyPolicyButton.exists)
            privacyPolicyButton.tap()
            XCTAssert(app.staticTexts["Privacy Policy"].waitForExistence(timeout: 2))
        }
    }
    
    func testInlineCardLayoutBGE() {
        if appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addCardButton = app.scrollViews.otherElements.buttons["Add credit/debit card"]
            XCTAssert(addCardButton.waitForExistence(timeout: 3))
            addCardButton.tap()

            XCTAssert(app.scrollViews.otherElements.textFields["Name on Card, required"].exists)
            XCTAssert(app.scrollViews.otherElements.textFields["Card Number, required"].exists)
            
            // Card IO test
            let cardIOButton = app.scrollViews.otherElements.buttons["Take a photo to scan credit card number"]
            XCTAssert(cardIOButton.exists)
            cardIOButton.tap()
            XCTAssert(app.navigationBars["Card"].waitForExistence(timeout: 2))
            app.navigationBars.buttons["Cancel"].tap()
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Expiration Date"].waitForExistence(timeout: 2))
            XCTAssert(app.scrollViews.otherElements.textFields["Month, two digits"].exists)
            XCTAssert(app.scrollViews.otherElements.textFields["Year, four digits"].exists)
            
            XCTAssert(app.scrollViews.otherElements.textFields["CVV, required"].exists)
            let cvvTooltip = app.scrollViews.otherElements.buttons["Tool tip"]
            XCTAssert(cvvTooltip.exists)
            cvvTooltip.tap()
            XCTAssert(app.staticTexts["What's a CVV?"].waitForExistence(timeout: 2))
            let closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            XCTAssert(app.scrollViews.otherElements.textFields["Zip Code, required"].waitForExistence(timeout: 2))
            
            let saveToWalletSwitch = app.scrollViews.otherElements.switches["Save to my wallet"]
            XCTAssert(saveToWalletSwitch.exists)
            if let switchValueStr = saveToWalletSwitch.value as? String {
                XCTAssert(switchValueStr == "1", "Save to My Wallet switch should be ON by default")
            } else {
                XCTFail("Could not get saveToWalletSwitch value")
            }
            XCTAssert(app.scrollViews.otherElements.staticTexts["Save to My Wallet"].exists)

            XCTAssert(app.scrollViews.otherElements.textFields["Nickname, required"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Set this payment account as default to easily pay from the Home and Bill screens."].exists)
            let defaultAccountSwitch = app.scrollViews.otherElements.switches["Default payment account"]
            if let switchValueStr = defaultAccountSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Default Payment Account switch should be OFF by default")
            } else {
                XCTFail("Could not get defaultAccountSwitch value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["A convenience fee will be applied to this payment. Residential accounts: $0.00. Business accounts: 0%."].exists)
            let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
            XCTAssert(paymentAmountTextField.exists)
            if let textFieldValue = paymentAmountTextField.value as? String {
                XCTAssert(textFieldValue == "$200.00", "Payment amount value entry should default to the amount due")
            } else {
                XCTFail("Could not get paymentAmountTextField value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: Date())
            let paymentDateButton = app.scrollViews.otherElements.buttons[dateString]
            XCTAssert(paymentDateButton.exists)
            paymentDateButton.tap()
            XCTAssert(app.navigationBars["Select Payment Date"].waitForExistence(timeout: 2))
        }
    }
    
    func testInlineCardLayoutComEdPECO() {
        if !appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addCardButton = app.scrollViews.otherElements.buttons["Add credit/debit card"]
            XCTAssert(addCardButton.waitForExistence(timeout: 3))
            addCardButton.tap()
            
            XCTAssert(app.scrollViews.otherElements.textFields["Card Number, required"].exists)
            
            // Card IO test
            let cardIOButton = app.scrollViews.otherElements.buttons["Take a photo to scan credit card number"]
            XCTAssert(cardIOButton.exists)
            cardIOButton.tap()
            XCTAssert(app.navigationBars["Card"].waitForExistence(timeout: 2))
            app.navigationBars.buttons["Cancel"].tap()
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Expiration Date"].waitForExistence(timeout: 2))
            XCTAssert(app.scrollViews.otherElements.textFields["Month, two digits"].exists)
            XCTAssert(app.scrollViews.otherElements.textFields["Year, four digits"].exists)
            
            XCTAssert(app.scrollViews.otherElements.textFields["CVV, required"].exists)
            let cvvTooltip = app.scrollViews.otherElements.buttons["Tool tip"]
            XCTAssert(cvvTooltip.exists)
            cvvTooltip.tap()
            XCTAssert(app.staticTexts["What's a CVV?"].waitForExistence(timeout: 2))
            let closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
            
            XCTAssert(app.scrollViews.otherElements.textFields["Zip Code, required"].waitForExistence(timeout: 2))
            
            let saveToWalletSwitch = app.scrollViews.otherElements.switches["Save to my wallet"]
            XCTAssert(saveToWalletSwitch.exists)
            if let switchValueStr = saveToWalletSwitch.value as? String {
                XCTAssert(switchValueStr == "1", "Save to My Wallet switch should be ON by default")
            } else {
                XCTFail("Could not get saveToWalletSwitch value")
            }
            XCTAssert(app.scrollViews.otherElements.staticTexts["Save to My Wallet"].exists)
            
            XCTAssert(app.scrollViews.otherElements.textFields["Nickname (Optional)"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Set this payment account as default to easily pay from the Home and Bill screens."].exists)
            let defaultAccountSwitch = app.scrollViews.otherElements.switches["Default payment account"]
            if let switchValueStr = defaultAccountSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Default Payment Account switch should be OFF by default")
            } else {
                XCTFail("Could not get defaultAccountSwitch value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["A $0.00 convenience fee will be applied by Bill Matrix, our payment partner."].exists)
            let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
            XCTAssert(paymentAmountTextField.exists)
            if let textFieldValue = paymentAmountTextField.value as? String {
                XCTAssert(textFieldValue == "$200.00", "Payment amount value entry should default to the amount due")
            } else {
                XCTFail("Could not get paymentAmountTextField value")
            }
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: Date())
            XCTAssert(app.scrollViews.otherElements.staticTexts[dateString].exists)
            XCTAssertFalse(app.scrollViews.otherElements.buttons[dateString].exists, "ComEd/PECO inline card should be fixed date")
            
            XCTAssert(app.scrollViews.otherElements.images["ic_billmatrix"].waitForExistence(timeout: 2))
            
            let privacyPolicyButton = app.scrollViews.otherElements.buttons["Privacy Policy"]
            XCTAssert(privacyPolicyButton.exists)
            privacyPolicyButton.tap()
            XCTAssert(app.staticTexts["Privacy Policy"].waitForExistence(timeout: 2))
        }
    }
    
    // MARK: Schedule Payments
    
    func testMakePaymentExistingWalletItem() {
        doLogin(username: "billCardWithDefaultPayment")
        selectTab(tabName: "Bill")
        tapButton(buttonText: "Make a Payment")
        
        let nextButton = app.navigationBars.buttons["Next"]
        XCTAssert(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()
        
        XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Account"].exists)
        XCTAssert(app.scrollViews.otherElements["Bank account, Test Nickname, Account number ending in, 1234"].exists)
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["--"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: Date())
        XCTAssert(app.scrollViews.otherElements.staticTexts[dateString].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Total Payment"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        
        let submitButton = app.navigationBars.buttons["Submit"]
        if appName.contains("BGE") {
            XCTAssert(submitButton.isEnabled, "BGE does not need to agree to terms so submit should be immediately enabled")
        } else {
            let termsButton = app.scrollViews.otherElements.buttons.element(boundBy: 0)
            XCTAssert(termsButton.exists)
            termsButton.tap()
            XCTAssert(app.staticTexts["Terms and Conditions"].waitForExistence(timeout: 2))
            let closeButton = app.buttons["Close"]
            XCTAssert(closeButton.exists)
            closeButton.tap()
        
            let termsSwitch = app.scrollViews.otherElements.switches["Yes, I have read, understand, and agree to the terms and conditions provided below:"]
            XCTAssert(termsSwitch.waitForExistence(timeout: 2))
            if let switchValueStr = termsSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Terms switch should be OFF by default")
            } else {
                XCTFail("Could not get termsSwitch value")
            }
            
            XCTAssertFalse(submitButton.isEnabled, "ComEd/PECO needs to agree to terms first so submit should be initially disabled")
            termsSwitch.tap()
            XCTAssert(submitButton.isEnabled)
        }
        submitButton.tap()
        
        XCTAssert(app.staticTexts["Payment Confirmation"].waitForExistence(timeout: 3))
        
        if appName.contains("BGE") {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Thank you for your payment."].exists)
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["Thank you for your payment. A confirmation email will be sent to you shortly."].exists)
        }
        
        XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts[dateString].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Paid"].exists)
        XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
        
        let closeButton = app.buttons["Close"]
        XCTAssert(closeButton.exists)
        closeButton.tap()
        
        XCTAssert(app.tabBars.buttons["Bill"].waitForExistence(timeout: 2), "Should be back on the bill tab after closing")
    }
    
    func testMakePaymentBGEOverpaying() {
        if appName.contains("BGE") {
            doLogin(username: "billCardWithDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let paymentAmountTextField = app.scrollViews.otherElements.textFields["Payment Amount, required"]
            XCTAssert(paymentAmountTextField.waitForExistence(timeout: 2))
            paymentAmountTextField.clearAndEnterText("30000")
            
            app.navigationBars.buttons["Next"].tap()
            
            XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
            XCTAssert(app.scrollViews.otherElements.staticTexts["You are scheduling a payment that may result in overpaying your amount due."].exists)
            
            XCTAssert(app.scrollViews.otherElements.staticTexts["Amount Due"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$200.00"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["Due Date"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["--"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["Overpaying"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$100.00"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Date"].exists)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: Date())
            XCTAssert(app.scrollViews.otherElements.staticTexts[dateString].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["Payment Amount"].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts["$300.00"].exists)
            
            let overpaySwitch = app.scrollViews.otherElements.switches["Yes, I acknowledge I am scheduling a payment for more than is currently due on my account."]
            XCTAssert(overpaySwitch.exists)
            if let switchValueStr = overpaySwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Overpay switch should be OFF by default")
            } else {
                XCTFail("Could not get termsSwitch value")
            }

            let submitButton = app.navigationBars.buttons["Submit"]
            XCTAssertFalse(submitButton.isEnabled, "Submit should be disabled until overpay switch is toggled")
            overpaySwitch.tap()
            XCTAssert(submitButton.isEnabled)
            submitButton.tap()
            
            XCTAssert(app.staticTexts["Payment Confirmation"].waitForExistence(timeout: 3))
        }
    }
    
    func testBGEInlineBankPayment() {
        if appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addBankButton = app.scrollViews.otherElements.buttons["Add bank account"]
            XCTAssert(addBankButton.waitForExistence(timeout: 3))
            addBankButton.tap()
            
            let nextButton = app.navigationBars.buttons["Next"]
            XCTAssertFalse(nextButton.isEnabled)
            
            app.scrollViews.otherElements.textFields["Bank Account Holder Name, required"].clearAndEnterText("Testy McTesterson")
            app.scrollViews.otherElements.textFields["Routing Number, required"].clearAndEnterText("022000046")
            app.scrollViews.otherElements.textFields["Account Number, required"].clearAndEnterText("1234567890")
            app.scrollViews.otherElements.textFields["Confirm Account Number, required"].clearAndEnterText("1234567890")
            app.scrollViews.otherElements.textFields["Nickname, required"].clearAndEnterText("Test nickname")
            
            XCTAssert(nextButton.isEnabled)
            nextButton.tap()
            
            XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
        }
    }
    
    func testBGEInlineCardPayment() {
        if appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addCardButton = app.scrollViews.otherElements.buttons["Add credit/debit card"]
            XCTAssert(addCardButton.waitForExistence(timeout: 3))
            addCardButton.tap()
            
            let nextButton = app.navigationBars.buttons["Next"]
            XCTAssertFalse(nextButton.isEnabled)
            
            app.scrollViews.otherElements.textFields["Name on Card, required"].clearAndEnterText("Testy McTesterson")
            app.scrollViews.otherElements.textFields["Card Number, required"].clearAndEnterText("5444009999222205")
            app.scrollViews.otherElements.textFields["Month, two digits"].clearAndEnterText("08")
            app.scrollViews.otherElements.textFields["Year, four digits"].clearAndEnterText("3000")
            app.scrollViews.otherElements.textFields["CVV, required"].clearAndEnterText("123")
            app.scrollViews.otherElements.textFields["Zip Code, required"].clearAndEnterText("10007")
            app.scrollViews.otherElements.textFields["Nickname, required"].clearAndEnterText("Test nickname")
            
            XCTAssert(nextButton.isEnabled)
            nextButton.tap()
            
            XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
            
            let pred = NSPredicate(format: "label like %@", "I have read and accept the Terms and Conditions below & E-Sign Disclosure and Consent Notice. Please review and retain a copy for your records.")
            let bgeCardSwitch = app.scrollViews.otherElements.switches.element(matching: pred)
            XCTAssert(bgeCardSwitch.exists)
            
            if let switchValueStr = bgeCardSwitch.value as? String {
                XCTAssert(switchValueStr == "0", "Switch should be OFF by default")
            } else {
                XCTFail("Could not get termsSwitch value")
            }
            
            let submitButton = app.navigationBars.buttons["Submit"]
            XCTAssert(submitButton.exists)
            XCTAssertFalse(submitButton.isEnabled)
            
            bgeCardSwitch.tap()
            XCTAssert(submitButton.isEnabled)
            submitButton.tap()
            XCTAssert(app.staticTexts["Payment Confirmation"].waitForExistence(timeout: 3))
        }
    }
    
    func testComEdPECOInlineBankPayment() {
        if !appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addBankButton = app.scrollViews.otherElements.buttons["Add bank account"]
            XCTAssert(addBankButton.waitForExistence(timeout: 3))
            addBankButton.tap()
            
            let nextButton = app.navigationBars.buttons["Next"]
            XCTAssertFalse(nextButton.isEnabled)
            
            app.scrollViews.otherElements.textFields["Routing Number, required"].clearAndEnterText("022000046")
            app.scrollViews.otherElements.textFields["Account Number, required"].clearAndEnterText("1234567890")
            app.scrollViews.otherElements.textFields["Confirm Account Number, required"].clearAndEnterText("1234567890")

            XCTAssert(nextButton.isEnabled)
            nextButton.tap()
            
            XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
        }
    }
    
    func testComEdPECOInlineCardPayment() {
        if !appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            selectTab(tabName: "Bill")
            tapButton(buttonText: "Make a Payment")
            
            let addCardButton = app.scrollViews.otherElements.buttons["Add credit/debit card"]
            XCTAssert(addCardButton.waitForExistence(timeout: 3))
            addCardButton.tap()
            
            let nextButton = app.navigationBars.buttons["Next"]
            XCTAssertFalse(nextButton.isEnabled)
            
            app.scrollViews.otherElements.textFields["Card Number, required"].clearAndEnterText("5444009999222205")
            app.scrollViews.otherElements.textFields["Month, two digits"].clearAndEnterText("08")
            app.scrollViews.otherElements.textFields["Year, four digits"].clearAndEnterText("3000")
            app.scrollViews.otherElements.textFields["CVV, required"].clearAndEnterText("123")
            app.scrollViews.otherElements.textFields["Zip Code, required"].clearAndEnterText("10007")
            
            XCTAssert(nextButton.isEnabled)
            nextButton.tap()
            
            XCTAssert(app.navigationBars["Review Payment"].waitForExistence(timeout: 2))
        }
    }

    
    // MARK: Helpers
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
}

