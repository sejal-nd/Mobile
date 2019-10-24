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
        launchApp()
        doLogin(username: "screenshots")
        selectTab(tabName: "More")
        
        continueAfterFailure = false
    }
    
    func testMoreTabLayout() {

        // Ensure all Cells & Buttons exist
        checkExistenceOfElements([
            (.button, "My Alerts"),
            (.button, "News and Updates"),
            (.button, "Change Password"),
            (.button, "Release of Info"),
            (.button, "Contact Us"),
            (.button, "Set Default Account"),
            (.button, "Policies and Terms")
        ])

        scrollToBottomOfTable()
        XCTAssertTrue(buttonElement(withText: "Sign Out", timeout: 5).isHittable)
        
        // Face ID/Touch ID buttons should not be shown because they are never enabled during UI testing
        if LAContext().biometryType == .faceID {
            XCTAssertFalse(app.cells.staticTexts["Face ID"].isHittable)
        } else if LAContext().biometryType == .touchID {
            XCTAssertFalse(app.cells.staticTexts["Touch ID"].isHittable)
        }
        
        if appOpCo == .bge {
            XCTAssertTrue(buttonElement(withText: "Set Default Account").isHittable)
        } else if appOpCo == .peco {
            XCTAssertTrue(buttonElement(withText: "Release of Info").isHittable)
        }
    }

    func testContactUsButtonAndLayout() {
        tapButton(buttonText: "Contact Us")
        XCTAssertTrue(app.navigationBars["Contact Us"].exists)

        checkExistenceOfElements([
            (.button, "Back"),
            (.staticText, "Emergency"),
            (.button, "Submit Form"),
            (.staticText, "Contact Us Online"),
            (.staticText, "M-F 7AM to 7PM"),
            (.staticText, "Use our online form to contact us with general questions. This form is for non-emergency purposes only."),
            (.button, "Facebook"),
            (.button, "Twitter"),
            (.button, "Flicker"),
            (.button, "YouTube"),
            (.button, "LinkedIn")
        ])

        if appOpCo == .bge {

            checkExistenceOfElements([
                (.link, "1-800-685-0123"),
                (.link, "1-800-265-6177"),
                (.link, "1-800-735-2258"),
                (.staticText, "Residential"),
                (.staticText, "Business"),
                (.staticText, "TTY/TTD"),
                (.staticText, "If you see downed power lines or smell natural gas, leave the area immediately and then call BGE. Representatives are available 24 hours a day, 7 days a week.")
            ])

        } else if appOpCo == .peco {

            checkExistenceOfElements([
                (.link, "1-800-841-4141"),
                (.link, "1-800-494-4000"),
                (.staticText, "All Customers"),
                (.staticText, "If you see downed power lines or smell natural gas, leave the area immediately and then call PECO. Representatives are available 24 hours a day, 7 days a week.")
            ])
        } else {

            checkExistenceOfElements([
                (.link, "1-800-334-7661"),
                (.link, "1-877-426-6331"),
                (.link, "1-800-955-8237"),
                (.staticText, "Residential"),
                (.staticText, "Business"),
                (.staticText, "Spanish"),
                (.staticText, "If you see downed power lines, leave the area immediately and then call ComEd. Representatives are available 24 hours a day, 7 days a week."),
                (.button, "Instagram"),
                (.button, "Pinterest")
            ])
        }
    }
    
    func testPoliciesAndTermsButtonAndLayout() {
        tapButton(buttonText: "Policies and Terms")
        checkExistenceOfElements([
            (.button, "Back"),
            (.navigationBar, "Policies and Terms")
        ])
        
        let privacyPred = NSPredicate(format: "label CONTAINS 'Privacy Policy'")
        let termsPred = NSPredicate(format: "label CONTAINS 'Terms of Use'")
        XCTAssertTrue(app.webViews.staticTexts.element(matching: privacyPred).waitForExistence(timeout: 5))
        XCTAssertTrue(app.webViews.staticTexts.element(matching: termsPred).waitForExistence(timeout: 5))
    }

    func testChangePasswordButtonAndLayout() {
        tapButton(buttonText: "Change Password")

        checkExistenceOfElements([
            (.navigationBar, "Change Password"),
            (.button, "Cancel"),
            (.button, "Submit"),
            (.secureTextField, "Current Password"),
            (.secureTextField, "New Password"),
            (.secureTextField, "Confirm Password")
        ])
    }

    func testChangePasswordSubmit() {
        tapButton(buttonText: "Change Password")

        let submitButton = app.navigationBars.buttons["Submit"]

        let elementsQuery = app.scrollViews.otherElements

        // Password strength view isn't shown yet
        XCTAssertFalse(elementsQuery.images["ic_check"].exists)
        elementsQuery.secureTextFields["New Password"].clearAndEnterText("pass")

        // Password strength view shown, criteria not yet met
        XCTAssertTrue(elementsQuery.staticTexts["Password strength weak"].exists)
        XCTAssertTrue(elementsQuery.images["ic_check"].exists)
        XCTAssertFalse(elementsQuery.images["Minimum password criteria met"].exists)
        elementsQuery.secureTextFields["New Password"].typeText("word1A")

        // Password strength view shown, criteria met
        XCTAssertTrue(elementsQuery.staticTexts["Password strength weak"].exists)
        XCTAssertTrue(elementsQuery.images["Minimum password criteria met"].exists)

        elementsQuery.secureTextFields["Confirm Password"].clearAndEnterText("password1A")

        // Submit still disabled
        XCTAssertFalse(submitButton.isEnabled)

        elementsQuery.secureTextFields["Current Password"].clearAndEnterText("Password1")

        // Fields all entered, submit now enabled
        XCTAssertTrue(submitButton.isEnabled)

        submitButton.tap()

        // "Password changed" toast shown
        checkExistenceOfElement(.staticText, "Password changed")
    }
    
    func testSignOut() {
        tapButton(buttonText: "Sign Out")

        let alert = app.alerts["Sign Out"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["No"].exists)
        XCTAssertTrue(alert.buttons["Yes"].exists)
        
        // Test "No" tap
        alert.buttons["No"].tap()
        XCTAssertFalse(alert.exists)
        
        tapButton(buttonText: "Sign Out")
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Test "Yes" tap
        alert.buttons["Yes"].tap()
        XCTAssertFalse(alert.exists)
        
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 5))
    }
}
