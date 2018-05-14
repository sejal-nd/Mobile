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
        XCTAssert(app.navigationBars.buttons["Back"].exists)
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
    
    func testMaintModeAll() {
        let signInButton = app.buttons["Sign In"]
        XCTAssert(signInButton.waitForExistence(timeout: 5))
        signInButton.tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("maintAll")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        
        let moreButton = app.tabBars.buttons["More"]
        XCTAssert(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()
        
        app.buttons["Sign out"].tap()
        app.alerts["Sign Out"].buttons["Yes"].tap()
        signInButton.tap()
        
        var mmStaticText: XCUIElement
        XCTAssert(elementsQuery.buttons["Reload"].exists)
        if appName.contains("BGE") {
            XCTAssert(elementsQuery.staticTexts["The BGE App is currently unavailable due to scheduled maintenance."].exists)
            
            //Parial string match needed to work around staticText 128 char query limit
            mmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your powe"]
            XCTAssertEqual(mmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222")
        }
        else if appName.contains("ComEd") {
            XCTAssert(elementsQuery.staticTexts["The ComEd App is currently unavailable due to scheduled maintenance."].exists)
            
            mmStaticText = app.staticTexts["If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24"]
            XCTAssertEqual(mmStaticText.value as? String, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-334-7661 M-F 7AM to 7PM\n\n")
        } else {
            XCTAssert(elementsQuery.staticTexts["The PECO App is currently unavailable due to scheduled maintenance."].exists)
            mmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representati"]
            XCTAssertEqual(mmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-494-4000 M-F 7AM to 7PM\n\n")
        }
    }
    private var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
}


