//
//  LoginTests.swift
//  LoginTests
//
//  Created by Joe Ezeh on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import AppCenterXCUITestExtensions

class LoginUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        handleTermsFirstLaunch()
    }
    
    func testLandingPageLayout() {
        checkExistenceOfElements([
            (.image, "img_logo_white"),
            (.button, "Sign In"),
            (.button, "Register"),
            (.button, "CONTINUE AS GUEST")
        ])
    }
    
    func testSignInPageLayout() {
        tapButton(buttonText: "Sign In")
        checkExistenceOfElements([
            (.textField, "Username / Email Address"),
            (.secureTextField, "Password"),
            (.image, "img_logo_white"),
            (.button, "Sign In"),
            (.switch, "Keep me signed in"),
            (.button, " username "),
            (.button, " password"),
            (.button, "Back")
        ])

        ACTLabel.labelStep("App center test -- test sign in page layout")
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
        ACTLabel.labelStep("App center test -- test sign in")
    }
    
    func testNoPassword() {
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("3012541000@example.com")

        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.alert, "Sign In Error")
        ACTLabel.labelStep("App center test -- test no pass")
    }
    
    func testNoUsername() {
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("Password3")

        tapButton(buttonText: "Sign In")
        
        checkExistenceOfElement(.alert, "Sign In Error")
        ACTLabel.labelStep("App center test -- test no username")
    }
    
    func testInvalidUsername(){
        tapButton(buttonText: "Sign In")
        let elementsQuery = app.scrollViews.otherElements
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("invalid@test.com")

        ACTLabel.labelStep("App center test -- invalid username -- just typed in username")
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("Password1")
        ACTLabel.labelStep("App center test -- invalid username -- just typed in pass")

        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.alert, "Sign In Error")
        ACTLabel.labelStep("App center test -- invalid username")
    }
    
    func testInvalidPassword() {
        tapButton(buttonText: "Sign In")
        let elementsQuery = app.scrollViews.otherElements
        
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssertTrue(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("valid@test.com")

        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        XCTAssertTrue(passwordSecureTextField.waitForExistence(timeout: 5))
        passwordSecureTextField.clearAndEnterText("oijrgoiwjothiqoij")

        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.alert, "Sign In Error")
        
        ACTLabel.labelStep("App center test -- invalid password")
    }
    
    func testContactUsAsGuest(){
        tapButton(buttonText: "CONTINUE AS GUEST")
        tapButton(buttonText: "Contact Us")

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
    
    func testMaintModeAll() {
        tapButton(buttonText: "Sign In")
        
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("maintAll")
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        tapButton(buttonText: "Sign In")
        
        let moreButton = app.tabBars.buttons["More"]
        XCTAssert(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()
        
        tapButton(buttonText: "Sign Out")
        app.alerts["Sign Out"].buttons["Yes"].tap()
        tapButton(buttonText: "Sign In")

        checkExistenceOfElement(.button, "Reload")

        if appOpCo == .bge {

            checkExistenceOfElement(.staticText, "The BGE App is currently unavailable due to maintenance.")
            
            //Parial string match needed to work around staticText 128 char query limit
            let mmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your powe"]
            XCTAssertEqual(mmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222")
        }
        else if appOpCo == .comEd {

            checkExistenceOfElement(.staticText, "The ComEd App is currently unavailable due to maintenance.")
            
            let mmStaticText = app.staticTexts["If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24"]
            XCTAssertEqual(mmStaticText.value as? String, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-334-7661 M-F 7AM to 7PM\n\n")
        } else {

            checkExistenceOfElement(.staticText, "The PECO App is currently unavailable due to maintenance.")

            let mmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representati"]
            XCTAssertEqual(mmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-494-4000 M-F 7AM to 7PM\n\n")
        }
    }
    
    func testUnauthOutageMaintMode() {
        tapButton(buttonText: "Sign In")
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText("maintAllTabs")

        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.clearAndEnterText("Password1")
        tapButton(buttonText: "Sign In")
        
        tapButton(buttonText: "More")
        
        tapButton(buttonText: "Sign Out")
        app.alerts["Sign Out"].buttons["Yes"].tap()
        tapButton(buttonText: "CONTINUE AS GUEST")
        tapButton(buttonText: "Report Outage")

        if appOpCo == .bge {
            //Parial string match needed to work around staticText 128 char query limit
            let outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your powe"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222")
        }
        else if appOpCo == .comEd {
            let outageMmStaticText = app.staticTexts["If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-334-7661 M-F 7AM to 7PM")
        }
        else {
            let outageMmStaticText = app.staticTexts["If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representati"]
            XCTAssertEqual(outageMmStaticText.value as? String, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n1-800-494-4000 M-F 7AM to 7PM")
        }
        
    }
}


