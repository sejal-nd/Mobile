//
//  MoreUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class MoreUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        doLogin(username: "valid@test.com")
        selectTab(tabName: "More")
        
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
        XCTAssert(app.navigationBars.buttons["Back"].exists)
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
        let elementsQuery = app.scrollViews.otherElements
        
        app.buttons["Contact us"].tap()
        XCTAssert(app.navigationBars.buttons["Back"].exists)
        XCTAssert(app.navigationBars["Contact Us"].exists)
        XCTAssert(elementsQuery.staticTexts["Emergency"].exists)
        XCTAssert(elementsQuery.buttons["Submit Form"].exists)
        XCTAssert(elementsQuery.staticTexts["Contact Us Online"].exists)
        XCTAssert(elementsQuery.staticTexts["M-F 7AM to 7PM"].exists)
        XCTAssert(elementsQuery.staticTexts["Use our online form to contact us with general questions. This form is for non-emergency purposes only."].exists)
        XCTAssert(elementsQuery.buttons["Facebook"].exists)
        XCTAssert(elementsQuery.buttons["Twitter"].exists)
        XCTAssert(elementsQuery.buttons["Flicker"].exists)
        XCTAssert(elementsQuery.buttons["YouTube"].exists)
        XCTAssert(elementsQuery.buttons["LinkedIn"].exists)

        if appName.contains("BGE"){
            XCTAssert(elementsQuery.links["1-800-685-0123"].exists)
            XCTAssert(elementsQuery.links["1-800-265-6177"].exists)
            XCTAssert(elementsQuery.links["1-800-735-2258"].exists)
            XCTAssert(elementsQuery.staticTexts["Residential"].exists)
            XCTAssert(elementsQuery.staticTexts["Business"].exists)
            XCTAssert(elementsQuery.staticTexts["TTY/TTD"].exists)
            let pred = NSPredicate(format: "label like %@", "If you see downed power lines or smell natural gas, leave the area immediately and then call BGE. Representatives are available 24 hours a day, 7 days a week.")
            XCTAssert(elementsQuery.staticTexts.element(matching: pred).exists)
            
        } else if appName.contains("PECO"){
            XCTAssert(elementsQuery.links["1-800-841-4141"].exists)
            XCTAssert(elementsQuery.links["1-800-494-4000"].exists)
            XCTAssert(elementsQuery.staticTexts["All Customers"].exists)
            let pred = NSPredicate(format: "label like %@", "If you see downed power lines or smell natural gas, leave the area immediately and then call PECO. Representatives are available 24 hours a day, 7 days a week.")
            XCTAssert(elementsQuery.staticTexts.element(matching: pred).exists)
        } else {
            XCTAssert(elementsQuery.links["1-800-334-7661"].exists)
            XCTAssert(elementsQuery.links["1-877-426-6331"].exists)
            XCTAssert(elementsQuery.links["1-800-955-8237"].exists)
            XCTAssert(elementsQuery.staticTexts["Residential"].exists)
            XCTAssert(elementsQuery.staticTexts["Business"].exists)
            XCTAssert(elementsQuery.staticTexts["Spanish"].exists)
            let pred = NSPredicate(format: "label like %@", "If you see downed power lines, leave the area immediately and then call ComEd. Representatives are available 24 hours a day, 7 days a week.")
            XCTAssert(elementsQuery.staticTexts.element(matching: pred).exists)
            XCTAssert(elementsQuery.buttons["Instagram"].exists)
            XCTAssert(elementsQuery.buttons["Pinterest"].exists)
        }
    }
    
    func testPoliciesAndTermsButtonAndLayout() {
        app.buttons["Policies and Terms"].tap()
        XCTAssert(app.navigationBars.buttons["Back"].exists)
        XCTAssert(app.navigationBars["Policies and Terms"].exists)
        
        let privacyPred = NSPredicate(format: "label CONTAINS 'Privacy Policy'")
        let termsPred = NSPredicate(format: "label CONTAINS 'Terms of Use'")
        XCTAssert(app.webViews.staticTexts.element(matching: privacyPred).waitForExistence(timeout: 5))
        XCTAssert(app.webViews.staticTexts.element(matching: termsPred).waitForExistence(timeout: 5))
    }
    
    func navigateToChangePassword() {
        app.buttons["Settings"].tap()
        app.tables.element(boundBy: 0).cells.element(boundBy: 0).tap()
    }
    
    func testChangePasswordButtonAndLayout() {
        navigateToChangePassword()
        
        XCTAssert(app.navigationBars.buttons["Cancel"].exists)
        XCTAssert(app.navigationBars.buttons["Submit"].exists)
        XCTAssert(app.navigationBars["Change Password"].exists)
        
        let elementsQuery = app.scrollViews.otherElements
        XCTAssert(elementsQuery.secureTextFields["Current Password"].exists)
        XCTAssert(elementsQuery.secureTextFields["New Password"].exists)
        XCTAssert(elementsQuery.secureTextFields["Confirm Password"].exists)
    }
    
    func testChangePasswordSubmit() {
        navigateToChangePassword()
        
        let submitButton = app.navigationBars.buttons["Submit"]
        
        let elementsQuery = app.scrollViews.otherElements
        
        // Password strength view isn't shown yet
        XCTAssert(!elementsQuery.images["ic_check"].exists)
        elementsQuery.secureTextFields["New Password"].clearAndEnterText("pass")
        
        // Password strength view shown, criteria not yet met
        XCTAssert(elementsQuery.staticTexts["Password strength weak"].exists)
        XCTAssert(elementsQuery.images["ic_check"].exists)
        XCTAssert(!elementsQuery.images["Minimum password criteria met"].exists)
        elementsQuery.secureTextFields["New Password"].typeText("word1A")
        
        // Password strength view shown, criteria met
        XCTAssert(elementsQuery.staticTexts["Password strength weak"].exists)
        XCTAssert(elementsQuery.images["Minimum password criteria met"].exists)
        
        elementsQuery.secureTextFields["Confirm Password"].clearAndEnterText("password1A")
        
        // Submit still disabled
        XCTAssert(!submitButton.isEnabled)
        
        elementsQuery.secureTextFields["Current Password"].clearAndEnterText("Password1")
        
        // Fields all entered, submit now enabled
        XCTAssert(submitButton.isEnabled)
        
        submitButton.tap()
        
        // "Password changed" toast shown
        XCTAssert(app.staticTexts["Password changed"].waitForExistence(timeout: 5))
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
