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
        
        ACTLabel.labelStep("First launch")
        let continueButton = app.buttons["Continue"]
        XCTAssert(continueButton.waitForExistence(timeout: 30))
        ACTLabel.labelStep("Continue button exists")
        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        let continueSwitch = app.switches.element(boundBy: 0)
        continueSwitch.tap()
        
        ACTLabel.labelStep("Continue switch tapped")
        // 19, 527
        
        if !continueButton.isEnabled{
            
//             // TAP GODDAMN EVERYTHING
//            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
//            outerloop: for x in 10...60{
//                for y in 526...530{
//                    print("tapping \(x) \(y)")
//
//                    let coordinate = normalized.withOffset(CGVector(dx: x, dy: y))
//                    coordinate.tap()
//                    if continueButton.isEnabled{
//                         print("OMG I FINALLY GOT IT!! \(x) \(y)")
////                        sleep(200000)
//                        break outerloop
//
//                    }
//                }
//            }
            
            
            
        }
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
    
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        ACTLabel.labelStep("Signed in")
    
    }

    func selectTab(tabName: String){
        ACTLabel.labelStep("Pre-select tab \(tabName)")
        let tab = app.tabBars.buttons[tabName]
        XCTAssert(tab.waitForExistence(timeout: 10))
        tab.tap()
        ACTLabel.labelStep("Post-select tab \(tabName)")
    }
    
    func tapButton(buttonText: String){
        ACTLabel.labelStep("Pre-tap button \(buttonText)")
        let makePaymentButton = app.scrollViews.otherElements.buttons[buttonText]
        XCTAssert(makePaymentButton.waitForExistence(timeout: 3))
        makePaymentButton.tap()
        ACTLabel.labelStep("Post-tap button \(buttonText)")
    }
}

