//
//  LoginTests.swift
//  LoginTests
//
//  Created by Joe Ezeh on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class LoginUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
    
        ACTLaunch.launch(app)
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        handleTermsFirstLaunch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func handleTermsFirstLaunch() {
        let continueButton = app.buttons["Continue"]
        XCTAssert(continueButton.waitForExistence(timeout: 30))

        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        app.switches.element(boundBy: 0).tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
        XCTAssert(app.buttons["Sign In"].waitForExistence(timeout: 5))
    }
    
    func testLandingPageLayout(){
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(app.buttons["Register"].exists)
        XCTAssert(app.buttons["CONTINUE AS GUEST"].exists)
        XCTAssert(app.images["img_logo_white"].exists)
    }
    
    func testSignInPageLayout() {
        let elementsQuery = app.scrollViews.otherElements
        
        app.buttons["Sign In"].tap()
        XCTAssert(elementsQuery.textFields["Username / Email Address"].exists)
        XCTAssert(elementsQuery.secureTextFields["Password"].exists)
        XCTAssert(elementsQuery.images["img_logo_white"].exists)
        XCTAssert(app.navigationBars.element(boundBy: 0).children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(app.scrollViews.otherElements.switches["Keep me signed in"].exists)
        XCTAssert(elementsQuery.buttons[" username "].exists)
        XCTAssert(elementsQuery.buttons[" password"].exists)
        ACTLabel.labelStep("App center test -- test sign in page layout")
    }
    
    func testSignIn(){
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        
        // Assert that the Home page loaded after a valid login
        XCTAssert(app.tabBars.buttons["Home"].exists, "User was not logged in after 15 seconds or login failed.")
        ACTLabel.labelStep("App center test -- test sign in")
    }
    
    func testNoPassword() {
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("3012541000@example.com")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(errorAlert.waitForExistence(timeout: 5))
        ACTLabel.labelStep("App center test -- test no pass")
    }
    
    func testNoUsername() {
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        
        XCTAssert(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(errorAlert.waitForExistence(timeout: 5))
        ACTLabel.labelStep("App center test -- test no username")
    }
    
    func testInvalidUsername(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("invalid@test.com")
        ACTLabel.labelStep("App center test -- invalid username -- just typed in username")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        ACTLabel.labelStep("App center test -- invalid username -- just typed in pass")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(errorAlert.waitForExistence(timeout: 5))
        ACTLabel.labelStep("App center test -- invalid username")
    }
    
    func testInvalidPassword(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("oijrgoiwjothiqoij")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(errorAlert.waitForExistence(timeout: 5))
        
        ACTLabel.labelStep("App center test -- invalid password")
        
    }

}
