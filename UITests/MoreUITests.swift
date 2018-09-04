//
//  MoreUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions
import LocalAuthentication

class MoreUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        doLogin(username: "User_8339951047@test.com")
        selectTab(tabName: "More")
        
        continueAfterFailure = false
    }
    
    func testMoreTabLayout() {

        // Ensure all Cells & Buttons exist
        XCTAssert(app.cells.staticTexts["My Alerts"].exists)
        XCTAssert(app.cells.staticTexts["News and Updates"].exists)
        XCTAssert(app.cells.staticTexts["Change Password"].exists)
        XCTAssert(app.cells.staticTexts["Release of Info"].exists)

        XCTAssert(app.cells.staticTexts["Contact Us"].exists)
        XCTAssert(app.cells.staticTexts["Set Default Account"].exists)
        XCTAssert(app.cells.staticTexts["Policies and Terms"].exists)
        
        XCTAssert(app.tables.buttons["Sign Out"].isHittable)
        
        
        // Face ID/Touch ID buttons should not be shown because they are never enabled during UI testing
        if #available(iOS 11.0, *) {
            if LAContext().biometryType == .faceID {
                XCTAssert(!app.cells.staticTexts["Face ID"].isHittable)
            } else if LAContext().biometryType == .touchID {
                XCTAssert(!app.cells.staticTexts["Touch ID"].isHittable)
            }
        }
        
        if appName.contains("BGE") {
            XCTAssert(app.cells.staticTexts["Default Account"].isHittable)
        } else if appName.contains("PECO") {
            XCTAssert(app.cells.staticTexts["Release of Info"].isHittable)
        }
    }

    func testContactUsButtonAndLayout() {

        let elementsQuery = app.scrollViews.otherElements
        
        app.tables/*@START_MENU_TOKEN@*/.cells.staticTexts["Contact Us"]/*[[".cells.staticTexts[\"Contact Us\"]",".staticTexts[\"Contact Us\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
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
        app.cells.staticTexts["Policies and Terms"].tap()
        XCTAssert(app.navigationBars.buttons["Back"].exists)
        XCTAssert(app.navigationBars["Policies and Terms"].exists)
        
        let privacyPred = NSPredicate(format: "label CONTAINS 'Privacy Policy'")
        let termsPred = NSPredicate(format: "label CONTAINS 'Terms of Use'")
        XCTAssert(app.webViews.staticTexts.element(matching: privacyPred).waitForExistence(timeout: 5))
        XCTAssert(app.webViews.staticTexts.element(matching: termsPred).waitForExistence(timeout: 5))
    }

    func testChangePasswordButtonAndLayout() {
        app.cells.staticTexts["Change Password"].tap()
        
        XCTAssert(app.navigationBars.buttons["Cancel"].exists)
        XCTAssert(app.navigationBars.buttons["Submit"].exists)
        XCTAssert(app.navigationBars["Change Password"].exists)

        let elementsQuery = app.scrollViews.otherElements
        XCTAssert(elementsQuery.secureTextFields["Current Password"].exists)
        XCTAssert(elementsQuery.secureTextFields["New Password"].exists)
        XCTAssert(elementsQuery.secureTextFields["Confirm Password"].exists)
    }

    func testChangePasswordSubmit() {
        app.cells.staticTexts["Change Password"].tap()

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
        let signOutButton = app.tables.buttons["Sign Out"]
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
