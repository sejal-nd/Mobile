//
//  LoginTests.swift
//  LoginTests
//
//  Created by Joe Ezeh on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class LoginUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        handleTermsFirstLaunch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func handleTermsFirstLaunch() {
        let continueButton = app.buttons["Continue"]

        waitForElementToAppear(continueButton)

        // Assert button is disabled when the switch is not enabled
        XCTAssert(!continueButton.isEnabled)
        app.switches.element(boundBy: 0).tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
        waitForElementToAppear(app.buttons["Sign In"])
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
    }
    
    func testSignIn(){
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        waitForElementToAppear(app.buttons["Next:"])
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        waitForElementToAppear(app.tabBars.buttons["Home"])
        
        // Assert that the Home page loaded after a valid login
        XCTAssert(app.tabBars.buttons["Home"].exists, "User was not logged in after 15 seconds or login failed.")
    }
    
    func testNoPassword() {
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        usernameEmailAddressTextField.clearAndEnterText("3012541000@example.com")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testNoUsername() {
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        
        waitForElementToAppear(passwordSecureTextField)
        passwordSecureTextField.tap()
        passwordSecureTextField.clearAndEnterText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testInvalidUsername(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        usernameEmailAddressTextField.clearAndEnterText("invalid@test.com")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testInvalidPassword(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.clearAndEnterText("oijrgoiwjothiqoij")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    //Helper function that waits for a specific element to appear
    func waitForElementToAppear (_ element: XCUIElement){
        let predicate = NSPredicate(format: "exists==true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
    
}

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        let characters = Array(stringValue)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: characters.count)
        
        self.typeText(deleteString)
        self.typeText(text)
    }
}
