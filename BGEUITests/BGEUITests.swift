//
//  BGEUITests.swift
//  BGEUITests
//
//  Created by Joe Ezeh on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class BGEUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func testTermsFirstLaunch() {
        let continueButton = app.buttons["Continue"]
        
        //Assert button is disabled when the switch is not checked
        //THIS TEST WILL FAIL IF THE APP HAS BEEN LAUNCHED BEFORE
        XCTAssert(!(continueButton.isEnabled))
        app.switches["0"].tap()
        XCTAssert(continueButton.isEnabled)
        continueButton.tap()
    }
    
    func testLandingPageLayout(){
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(app.buttons["Register"].exists)
        XCTAssert(app.buttons["SKIP FOR NOW"].exists)
        XCTAssert(app.images["img_logo_white"].exists)
    }
    
    func testSignInPageLayout(){
        let elementsQuery = app.scrollViews.otherElements
        
        app.buttons["Sign In"].tap()
        XCTAssert(elementsQuery.textFields["Username / Email Address"].exists)
        XCTAssert(elementsQuery.secureTextFields["Password"].exists)
        XCTAssert(elementsQuery.images["img_logo_white"].exists)
        XCTAssert(app.navigationBars["BGE.LoginView"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(elementsQuery.switches["0"].exists)
        XCTAssert(elementsQuery.buttons["Forgot password or username?"].exists)
        XCTAssert(elementsQuery.buttons["Sign In"].exists)
    }
    
    func testSignIn(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]

        
        usernameEmailAddressTextField.tap()
        clearText(usernameEmailAddressTextField)
        usernameEmailAddressTextField.typeText("multprem03")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        //Assert that the Home page loaded after a valid login
        waitForElementToAppear(app.navigationBars["Home"])
        XCTAssert(app.navigationBars["Home"].staticTexts["Home"].exists)
    }
    
    func testNoPassword(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Error"]
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        
        
        usernameEmailAddressTextField.tap()
        clearText(usernameEmailAddressTextField)
        usernameEmailAddressTextField.typeText("multprem03")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testNoUsername(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Error"]
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testInvalidUsername(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        usernameEmailAddressTextField.tap()
        usernameEmailAddressTextField.typeText("oisrjthowrothwoitj")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testInvalidPassword(){
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        usernameEmailAddressTextField.tap()
        usernameEmailAddressTextField.typeText("multprem03")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("oijrgoiwjothiqoij")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    //Helper function to delete text from a field, 12 is arbitrary
    func clearText (_ field: XCUIElement){
        for _ in 0...12{
            field.typeText(XCUIKeyboardKeyDelete)
        }
    }
    
    //Helper function that waits for a specific element to appear
    func waitForElementToAppear (_ element: XCUIElement){
        let predicate = NSPredicate(format: "exists==true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
