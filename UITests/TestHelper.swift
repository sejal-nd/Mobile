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
        sleep(5)
    }
    
    override func tearDown() {
        ACTLabel.labelStep("Tearing down")

        super.tearDown()
    }
    
    func handleTermsFirstLaunch() {
        let continueButton = app.buttons["Continue"]
        XCTAssert(continueButton.waitForExistence(timeout: 30))
        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        let continueSwitch = app.switches.element(boundBy: 0)
        continueSwitch.tap()
        
        var i = 0
        while !continueButton.isEnabled {
            // seems the app sometimes has trouble starting up quickly enough for the button to react?
            usleep(50000)
            continueSwitch.tap()
            i += 1
            if i > 10{
                break
            }
        }
        ACTLabel.labelStep("Continue switch tapped")
        continueButton.tap()
        ACTLabel.labelStep("Continue button tapped")
        XCTAssert(app.buttons["Sign In"].waitForExistence(timeout: 5))
        ACTLabel.labelStep("Sign in ready")
    }
    
    func doLogin(username: String) {
    
        handleTermsFirstLaunch()
    
        let signInButton = app.buttons["Sign In"]
        XCTAssert(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText(username)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        ACTLabel.labelStep("Signing in...")
        elementsQuery.buttons["Sign In"].tap()
    
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 20))
        ACTLabel.labelStep("Signed in")
    }

    func selectTab(tabName: String){
        ACTLabel.labelStep("Pre-select tab \(tabName)")
        let tab = app.tabBars.buttons[tabName]
        XCTAssert(tab.waitForExistence(timeout: 20))
        tab.tap()
        sleep(1)
        ACTLabel.labelStep("Post-select tab \(tabName)")
    }
    
    func tapButton(buttonText: String){
        ACTLabel.labelStep("Pre-tap button \(buttonText)")
        var button: XCUIElement?
       
        // Buttons could be anywhere in the view hierarchy...
        let buttonInScrollView = app.scrollViews.otherElements.buttons[buttonText]
        let buttonInApp = app.buttons[buttonText]
        let buttonInTableView = app.tables.buttons[buttonText]
        let buttonDescendants = app.buttons.descendants(matching: XCUIElement.ElementType.button).matching(NSPredicate(format: "label CONTAINS '\(buttonText)'")).firstMatch
        let lastDitchEffort = app.staticTexts[buttonText]
        
        if buttonInScrollView.waitForExistence(timeout: 3){
            button = buttonInScrollView
        } else if buttonInApp.waitForExistence(timeout: 3){
            button = buttonInApp
        } else if buttonInTableView.waitForExistence(timeout: 3){
            button = buttonInTableView
        } else if buttonDescendants.waitForExistence(timeout: 3){
            button = buttonDescendants
        } else if lastDitchEffort.waitForExistence(timeout: 3){
            button = lastDitchEffort
        }
        
        guard let buttonToTap = button else {
            XCTFail("Unable to locate button with text \(buttonText)")
            return
        }
        buttonToTap.tap()
        sleep(1)
        ACTLabel.labelStep("Post-tap button \(buttonText)")
        
       
    }
}

