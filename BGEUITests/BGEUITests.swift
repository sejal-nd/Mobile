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
        //Slightly redundant, but this is the easiest way to wait for the splash screen to finish
        waitForElementToAppear(app.buttons["Sign In"])
        
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(app.buttons["Register"].exists)
        XCTAssert(app.buttons["CONTINUE AS GUEST"].exists)
        XCTAssert(app.images["img_logo_white"].exists)
    }
    
    func testSignInPageLayout(){
        let elementsQuery = app.scrollViews.otherElements
        
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        XCTAssert(elementsQuery.textFields["Username / Email Address"].exists)
        XCTAssert(elementsQuery.secureTextFields["Password"].exists)
        XCTAssert(elementsQuery.images["img_logo_white"].exists)
        XCTAssert(app.navigationBars["BGE.LoginView"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.buttons["Sign In"].exists)
        XCTAssert(app.scrollViews.otherElements.switches["Keep me signed in"].exists)
        XCTAssert(elementsQuery.buttons[" username "].exists)
        XCTAssert(elementsQuery.buttons[" password"].exists)
    }
    
    func testSignIn(){
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        waitForElementToAppear(app.buttons["Next:"])
        clearText()
        usernameEmailAddressTextField.typeText("3012541000@example.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        waitForElementToAppear(app.tabBars.buttons["Home"])
        
        //Assert that the Home page loaded after a valid login
        //WILL GET CAUGHT UP ON PUSH NOTFICATION ALERT ON FIRST SIGN FOR NOW
        XCTAssert(app.tabBars.buttons["Home"].exists, "User was not logged in after 15 seconds or login failed.")
    }
    
    func testNoPassword(){
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
        usernameEmailAddressTextField.tap()
        
        
        
        clearText()
        usernameEmailAddressTextField.typeText("3012541000@example.com")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testNoUsername(){
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        
        waitForElementToAppear(passwordSecureTextField)
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("Password3")
        elementsQuery.buttons["Sign In"].tap()
        
        waitForElementToAppear(errorAlert)
        XCTAssert(errorAlert.exists)
    }
    
    func testInvalidUsername(){
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
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
        waitForElementToAppear(app.buttons["Sign In"])
        app.buttons["Sign In"].tap()
        let elementsQuery = app.scrollViews.otherElements
        let errorAlert = app.alerts["Sign In Error"]
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        waitForElementToAppear(usernameEmailAddressTextField)
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
    func clearText(){
        waitForElementToAppear(app.keys["delete"])
        for _ in 0...21{
            app/*@START_MENU_TOKEN@*/.keys["delete"]/*[[".keyboards.keys[\"delete\"]",".keys[\"delete\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        }
        
            //field.typeText(XCUIKeyboardKey.delete.rawValue)
    }
    
    //Helper function that waits for a specific element to appear
    func waitForElementToAppear (_ element: XCUIElement){
        let predicate = NSPredicate(format: "exists==true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    //Helper function that waits for a specific element to appear
    func waitForLogin (_ element: XCUIElement){
        let predicate = NSPredicate(format: "exists==true")
        expectation(for: predicate, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
    
}
