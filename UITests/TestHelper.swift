//
//  TestHelper.swift
//  BGE
//
//  Created by Peter Harris on 6/22/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import XCTest

let appOpCo: OpCo = {
    guard let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String,
        let bundleId = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            fatalError("Could not resolve appName or bundle id in UI Tests.")
    }
    
    let opCoName: String
    switch bundleId {
    case "BGEUITests-Runner":
        opCoName = "BGE"
    case "ComEdUITests-Runner":
        opCoName = "ComEd"
    case "PECOUITests-Runner":
        opCoName = "PECO"
    default:
        fatalError("Invalid bundle Id resolving to OpCo Name.")
    }

    return OpCo(rawValue: opCoName)!
}()

class ExelonUITestCase: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launchArguments = ["UITest"]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func launchApp() {
        app.launch()
        
        app.launchEnvironment = ["animations": "0"]
    }
    
    func handleTermsFirstLaunch() {
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(buttonElement(withText: "Continue", timeout: 5).exists)
        // Assert button is disabled when the switch is not enabled
        XCTAssertFalse(continueButton.isEnabled)

        while !continueButton.isEnabled {
            XCUIApplication().otherElements[String(format: NSLocalizedString("I agree to %@'s Privacy Policy and Terms of Use., Checkbox, Unchecked", comment: ""), appOpCo.rawValue)].tap()
        }

        continueButton.tap()
       
        XCTAssertTrue(buttonElement(withText: "Sign In", timeout: 5).exists)
    }
    
    func doLogin(username: String) {
        handleTermsFirstLaunch()
    
        let signInButton = buttonElement(withText: "Sign In", timeout: 5)
        XCTAssertTrue(signInButton.exists)
        signInButton.tap()
    
        let elementsQuery = app.scrollViews.otherElements
        let usernameEmailAddressTextField = elementsQuery.textFields["Username / Email Address"]
        XCTAssert(usernameEmailAddressTextField.waitForExistence(timeout: 5))
        usernameEmailAddressTextField.clearAndEnterText(username)
        
        let passwordSecureTextField = elementsQuery.secureTextFields["Password"]
        passwordSecureTextField.pasteText(app: app, "Password1")
        
        tapButton(buttonText: "Sign In")
    
        if app.launchArguments.contains("stormMode") {
            checkExistenceOfElement(.staticText, "Storm mode is in effect. Due to severe weather, the most relevant features are optimized to allow us to better serve you.")
        } else {
            XCTAssertTrue(tabButtonElement(withText: "Home").exists)
        }
        
        // Handle Commercial Usage
        let closeButton = app.buttons["Close"]
        
        if closeButton.exists {
            closeButton.tap()
        }
    }
}


// MARK: - Helpers

extension ExelonUITestCase {

    func selectTab(tabName: String) {
        let tab = tabButtonElement(withText: tabName, timeout: 20)
        XCTAssertTrue(tab.exists)
        tab.tap()
    }
    
    func tapButton(buttonText: String) {
        let button = buttonElement(withText: buttonText)
        XCTAssertTrue(button.exists)
        button.tap()
    }

    func scrollToBottomOfTable() {
        let table = app.tables.element(boundBy: 0)
        let lastCell = table.cells.element(boundBy: table.cells.count - 1)
        table.scrollToElement(lastCell)
        table.swipeUp() // In case the last cell becomes visible but we're looking for another element inside or the footer view
    }

    func checkExistenceOfElements(_ typesAndTexts: [(XCUIElement.ElementType, String)],
                                  timeout: TimeInterval = 3,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        for (type, text) in typesAndTexts {
            checkExistenceOfElement(type, text, timeout: timeout, file: file, line: line)
        }
    }

    func checkExistenceOfElement(_ type: XCUIElement.ElementType,
                                 _ text: String,
                                 timeout: TimeInterval = 3,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        XCTAssertTrue(
            element(ofType: type, withText: text, timeout: timeout).exists,
            "Element with text \"\(text)\" could not be found.",
            file: file,
            line: line
        )
    }
    
    func checkNonexistenceOfElements(_ typesAndTexts: [(XCUIElement.ElementType, String)],
                                     timeout: TimeInterval = 3,
                                     file: StaticString = #file,
                                     line: UInt = #line) {
        for (type, text) in typesAndTexts {
            checkNonexistenceOfElement(type, text, timeout: timeout, file: file, line: line)
        }
    }
    
    func checkNonexistenceOfElement(_ type: XCUIElement.ElementType,
                                    _ text: String,
                                    timeout: TimeInterval = 3,
                                    file: StaticString = #file,
                                    line: UInt = #line) {
        XCTAssertTrue(
            !element(ofType: type, withText: text, timeout: timeout).exists,
            "Element with text \"\(text)\" could not be found.",
            file: file,
            line: line
        )
    }

    func tabButtonElement(withText text: String, timeout: TimeInterval = 5) -> XCUIElement {
        let tab = app.tabBars.buttons[text]

        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: tab, handler: nil)
        waitForExpectations(timeout: timeout, handler: nil)

        return tab
    }

    func buttonElement(withText text: String, timeout: TimeInterval = 3) -> XCUIElement {
        return element(ofType: .button, withText: text, timeout: timeout)
    }

    func staticTextElement(withText text: String, timeout: TimeInterval = 3) -> XCUIElement {
        return element(ofType: .staticText, withText: text, timeout: timeout)
    }

    /// Search for element in multiple locations within the view hierarchy
    func element(ofType type: XCUIElement.ElementType, withText text: String, timeout: TimeInterval = 3) -> XCUIElement {
        assert(type != .other, "It is not safe to use ElementType \"other\" in this helper method as it can create a recursive loop")

        let shouldOnlyUsePredicates: Bool = text.count > 128

        let inDescendants = app.descendants(matching: type).descendants(matching: type).matching(labelPredicate(forText: text)).firstMatch
        let closeMatch = app.descendants(matching: type).element(matching: labelPredicate(forText: text)).firstMatch

        var possibleElements: [XCUIElement] = [inDescendants, closeMatch]

        if !shouldOnlyUsePredicates {
            let inScrollView = app.scrollViews.otherElements.descendants(matching: type)[text]
            let inApp = app.descendants(matching: type)[text]
            let inTableView = app.tables.descendants(matching: type)[text]
            let inTabBar = app.tabBars.descendants(matching: type)[text]
            let inNavBar = app.navigationBars.descendants(matching: type)[text]
            let inSheet = app.sheets.descendants(matching: type)[text]
            let lastDitchEffort = app.staticTexts[text]

            possibleElements.append(contentsOf: [inScrollView, inApp, inTableView, inTabBar, inNavBar, inSheet, lastDitchEffort])
        }

        let matchFilter: (XCUIElement) -> Bool = { $0.exists && $0.elementType == type }
        var elapsedTime: TimeInterval = 0

        while elapsedTime < timeout {

            if let validElement = possibleElements.lazy.filter(matchFilter).first {
                return validElement
            }
            usleep(200000) // sleep for .2 seconds
            elapsedTime += 0.2
        }

        return app.descendants(matching: type)["Intentionally Returning an element that does not exist"]
    }

    /// Breaks down multi-line text for predicate use
    private func labelPredicate(forText text: String) -> NSPredicate {
        let linesOfText = text.components(separatedBy: "\n")
        var format = "label CONTAINS %@"
        var formatArgsArray = [linesOfText.first!]

        if linesOfText.count > 1 {
            for i in 1..<linesOfText.count where !linesOfText[i].isEmpty {
                format += " AND label CONTAINS %@"
                formatArgsArray.append(linesOfText[i])
            }
        }
        return NSPredicate(format: format, argumentArray: formatArgsArray)
    }
}

extension XCUIElement {
    func scrollToElement(_ element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}
