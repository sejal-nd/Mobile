//
//  LoginTests.swift
//  LoginTests
//
//  Created by Joe Ezeh on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest


class LoginUITests: ExelonUITestCase {
    override func setUp() {
        super.setUp()
        launchApp()
        handleTermsFirstLaunch()
    }
    
    func testLandingPageLayout() {
        checkExistenceOfElements([
            (.image, "img_logo_white"),
            (.button, "Sign In"),
            (.button, "Register"),
            (.button, "Continue as Guest")
        ])
    }
    
    func testSignInPageLayout() {
        tapButton(buttonText: "Sign In")
        checkExistenceOfElements([
            (.textField, "Username / Email Address"),
            (.secureTextField, "Password"),
            (.image, "img_logo_white"),
            (.button, "Sign In"),
            (.button, "Forgot your username or password?"),
            (.button, "Back")
        ])
    }
    
    func testSignIn(){
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        tapButton(buttonText: "Sign In")
        checkExistenceOfElement(.button, "Home", timeout: 5)
        
        // Assert that the Home page loaded after a valid login
        XCTAssertTrue(app.tabBars.buttons["Home"].exists, "User was not logged in after 15 seconds or login failed.")
    }
    
    func testNoPassword() {
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("3012541000@example.com")

        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.alert, "Sign In Error")

    }
    
    func testNoUsername() {
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("Password3")

        tapButton(buttonText: "Sign In")
        
        checkExistenceOfElement(.alert, "Sign In Error")
    }
    
    func testInvalidUsername(){
        tapButton(buttonText: "Sign In")
        let elementsQuery = app.scrollViews.otherElements
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("invalid@test.com")

        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("Password1")

        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.alert, "Sign In Error")
    }
    
    func testInvalidPassword() {
        tapButton(buttonText: "Sign In")
        let elementsQuery = app.scrollViews.otherElements
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("invalid")
        
        tapButton(buttonText: "Sign In")
        
        checkExistenceOfElement(.alert, "Sign In Error")
        
    }
    
    func testContactUsAsGuest(){
        tapButton(buttonText: "Continue as Guest")
        
        let tableView = app.tables.matching(identifier: "guestTableView")
        let cell = tableView.cells.element(matching: .cell, identifier: "Contact Us")
        cell.tap()
        
        sleep(3) // test may be needed for azure ui tests
        
        checkExistenceOfElements([
            (.navigationBar, "Contact Us"),
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
        
        switch appOpCo {
        case .bge:
            checkExistenceOfElements([
                (.link, "1-800-685-0123"),
                (.link, "1-800-265-6177"),
                (.link, "1-800-735-2258"),
                (.staticText, "Residential"),
                (.staticText, "Business"),
                (.staticText, "TTY/TTD"),
                (.staticText, "If you see downed power lines or smell natural gas, leave the area immediately and then call BGE. Representatives are available 24 hours a day, 7 days a week.")
            ])
        case .comEd:
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
        case .peco:
            checkExistenceOfElements([
                (.link, "1-800-841-4141"),
                (.link, "1-800-494-4000"),
                (.staticText, "All Customers"),
                (.staticText, "If you see downed power lines or smell natural gas, leave the area immediately and then call PECO. Representatives are available 24 hours a day, 7 days a week.")
            ])
        }
    }
}
