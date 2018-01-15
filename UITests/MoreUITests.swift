//
//  MoreUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class MoreUITests: XCTestCase {
        
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
        app.launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        doLoginAndNavigateToMoreTab()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func doLoginAndNavigateToMoreTab() {
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
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        elementsQuery.buttons["Sign In"].tap()
        
        XCTAssert(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["More"].tap()
    }
    
    func testMoreTabLayout() {
        // Ensure all buttons exist
        XCTAssert(app.buttons["Settings"].exists)
        XCTAssert(app.buttons["Contact us"].exists)
        XCTAssert(app.buttons["Policies and Terms"].exists)
        XCTAssert(app.buttons["Sign out"].exists)
        
        // Ensure version label exists
        let predicate = NSPredicate(format: "label BEGINSWITH 'Version'")
        XCTAssert(app.staticTexts.element(matching: predicate).exists)
    }
    
    func testSettingsButtonAndLayout() {
        app.buttons["Settings"].tap()
        XCTAssert(app.navigationBars.element(boundBy: 0).children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.navigationBars["Settings"].exists)
        
        let tableCells = app.tables.element(boundBy: 0).cells
        XCTAssert(tableCells.element(boundBy: 0).staticTexts["Change Password"].exists)
        
        // Face ID/Touch ID buttons should not be shown because they are never enabled during UI testing
        XCTAssert(!tableCells.element(boundBy: 1).staticTexts["Face ID"].exists)
        XCTAssert(!tableCells.element(boundBy: 1).staticTexts["Touch ID"].exists)
        
        if appName.contains("BGE") {
            XCTAssert(tableCells.element(boundBy: 1).staticTexts["Default Account"].exists)
        } else if appName.contains("PECO") {
            XCTAssert(tableCells.element(boundBy: 1).staticTexts["Release of Info"].exists)
        }
    }
    
    func testContactUsButtonAndLayout() {
        app.buttons["Contact us"].tap()
        XCTAssert(app.navigationBars.element(boundBy: 0).children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.navigationBars["Contact Us"].exists)
    }
    
    func testPoliciesAndTermsButtonAndLayout() {
        app.buttons["Policies and Terms"].tap()
        XCTAssert(app.navigationBars.element(boundBy: 0).children(matching: .button).matching(identifier: "Back").element(boundBy: 0).exists)
        XCTAssert(app.navigationBars["Policies and Terms"].exists)
    }
    
    func testSignOut() {
        let signOutButton = app.buttons["Sign out"]
        let alert = app.alerts["Sign Out"]
        
        signOutButton.tap()
        XCTAssert(alert.waitForExistence(timeout: 5))
        XCTAssert(alert.buttons["No"].exists)
        XCTAssert(alert.buttons["Yes"].exists)
        
        // Test "No" tap
        alert.buttons["No"].tap()
        XCTAssert(!alert.exists)
        
        signOutButton.tap()
        XCTAssert(alert.waitForExistence(timeout: 5))
        
        // Test "Yes" tap
        alert.buttons["Yes"].tap()
        XCTAssert(!alert.exists)
        
        XCTAssert(app.buttons["Sign In"].waitForExistence(timeout: 5))
    }
    
    var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
    
}
