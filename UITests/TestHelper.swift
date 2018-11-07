//
//  TestHelper.swift
//  BGE
//
//  Created by Peter Harris on 6/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import AppCenterXCUITestExtensions
import XCTest


class ExelonUITestCase: XCTestCase{
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        ACTLaunch.launch(app)
    }
    
    override func tearDown() {
        ACTLabel.labelStep("Tearing down")

        super.tearDown()
    }

    func dateString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.calendar = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return dateFormatter.string(from: date)
    }
    
    func handleTermsFirstLaunch() {
        let continueButton = buttonElement(withText: "Continue")
        XCTAssertTrue(continueButton.exists)
        // Assert button is disabled when the switch is not enabled
        XCTAssertFalse(continueButton.isEnabled)
        let continueSwitch = app.switches.element(boundBy: 0)
        continueSwitch.tap()
        
        var i = 0
        while !continueButton.isEnabled {
            // seems the app sometimes has trouble starting up quickly enough for the button to react?
            usleep(50000)
            continueSwitch.tap()
            i += 1
            if i > 10 {
                break
            }
        }
        ACTLabel.labelStep("Continue switch tapped")
        continueButton.tap()
        ACTLabel.labelStep("Continue button tapped")
        XCTAssertTrue(buttonElement(withText: "Sign In", timeout: 5).exists)
        ACTLabel.labelStep("Sign in ready")
    }
    
    func doLogin(username: String) {
    
        handleTermsFirstLaunch()
    
        let signInButton = buttonElement(withText: "Sign In", timeout: 5)
        XCTAssertTrue(signInButton.exists)
        signInButton.tap()
    
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText(username)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        ACTLabel.labelStep("Signing in...")
        tapButton(buttonText: "Sign In")
    
        XCTAssertTrue(tabButtonElement(withText: "Home").exists)
        ACTLabel.labelStep("Signed in")
    }

    func selectTab(tabName: String) {
        ACTLabel.labelStep("Pre-select tab \(tabName)")
        let tab = tabButtonElement(withText: tabName, timeout: 20)
        XCTAssertTrue(tab.exists)
        tab.tap()
        ACTLabel.labelStep("Post-select tab \(tabName)")
    }
    
    func tapButton(buttonText: String) {
        ACTLabel.labelStep("Pre-tap button \(buttonText)")
        let button = buttonElement(withText: buttonText)
        XCTAssertTrue(button.exists)
        button.tap()
        ACTLabel.labelStep("Post-tap button \(buttonText)")
    }

    func tabButtonElement(withText text: String, timeout: TimeInterval = 5) -> XCUIElement {
        let tab = app.tabBars.buttons[text]

        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: tab, handler: nil)
        waitForExpectations(timeout: timeout, handler: nil)

        return tab
    }

    func buttonElement(withText text: String, timeout: TimeInterval = 3) -> XCUIElement {
        return element(ofType: .button, withText: text, timeout: timeout)
    }

    func staticTextElement(withText text: String, timeout: TimeInterval = 3) -> XCUIElement {
        return element(ofType: .staticText, withText: text, timeout: timeout)
    }

    private func element(ofType type: XCUIElement.ElementType, withText text: String, timeout: TimeInterval) -> XCUIElement {
        // Could be anywhere in the view hierarchy...
        let inScrollView = app.scrollViews.otherElements.descendants(matching: type)[text]
        let inApp = app.descendants(matching: type)[text]
        let inTableView = app.tables.descendants(matching: type)[text]
        let inTabBar = app.tabBars.descendants(matching: type)[text]
        let inDescendants = app.descendants(matching: type).descendants(matching: type).matching(NSPredicate(format: "label CONTAINS '\(text)'")).firstMatch
        let closeMatch = app.descendants(matching: type).element(matching: NSPredicate(format: "label CONTAINS '\(text)'"))
        let lastDitchEffort = app.staticTexts[text]

        var elapsedTime: TimeInterval = 0
        while elapsedTime < timeout {

            if let validElement = [inScrollView, inApp, inTableView, inTabBar, closeMatch, inDescendants, lastDitchEffort].lazy.filter({ $0.exists }).first {
                return validElement
            }
            usleep(200000) // sleep for .2 seconds
            elapsedTime += 0.2
        }

        return closeMatch
    }
}

extension XCUIElement {
    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}
