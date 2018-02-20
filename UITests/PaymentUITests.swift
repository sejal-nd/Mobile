//
//  PaymentUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class PaymentUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
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
        
        let makePaymentButton = app.scrollViews.otherElements.buttons["Make a Payment"]
        XCTAssert(makePaymentButton.waitForExistence(timeout: 3))
        makePaymentButton.tap()
    }
    
    func testLayoutNoPaymentMethods() {
        doLogin(username: "billCardNoDefaultPayment")
        
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
            XCTAssert(app.scrollViews.otherElements.staticTexts[NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")].exists)
        } else {
            XCTAssert(app.scrollViews.otherElements.staticTexts["A $0.00 convenience fee will be applied by Bill Matrix, our payment partner."].exists)
            XCTAssert(app.scrollViews.otherElements.staticTexts[NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")].exists)
        }
        XCTAssert(app.scrollViews.otherElements.buttons["Add credit/debit card"].exists)
    }
    
    func testInlineBankLayoutBGE() {
        if appName.contains("BGE") {
            doLogin(username: "billCardNoDefaultPayment")
            
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
            
            let addBankButton = app.scrollViews.otherElements.buttons["Add credit/debit card"]
            XCTAssert(addBankButton.waitForExistence(timeout: 3))
            addBankButton.tap()

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
    
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
}

