//
//  WalletUITests.swift
//  Mobile
//
//  Created by Joe Ezeh on 5/7/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class WalletUITests: XCTestCase {
    
    let app = XCUIApplication()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        ACTLaunch.launch(app)

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    //MARK: App name helper
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
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
    }
    
    func testCvvText() {
        doLogin(username: "billCardWithDefaultPayment")
        
        let billTab = app.tabBars.buttons["Bill"]
        billTab.tap()
        XCTAssertTrue(billTab.isSelected)
        
        let elementsQuery = app.scrollViews.otherElements
        
        elementsQuery.buttons["My Wallet"].tap()
        app.buttons["Add Credit card"].tap()
        elementsQuery.buttons["Tool tip"].tap()
        var cvvText:XCUIElement
        
        if appName.contains("BGE") {
            cvvText = elementsQuery.staticTexts["Your security code is usually a 3 or 4 digit number found on your card."]
            
        }
        else {
            cvvText = elementsQuery.staticTexts["Your security code is usually a 3 digit number found on the back of your card."]
        }
        XCTAssert(cvvText.waitForExistence(timeout: 2))
        XCTAssert(app.staticTexts["What's a CVV?"].exists)
        XCTAssert(elementsQuery.containing(.image, identifier:"cvv_info").element.exists)
        XCTAssert(app.buttons["Close"].exists)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}
