//
//  UITestExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 1/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(_ text: String) {
        
        if self.elementType != XCUIElement.ElementType.textField && self.elementType != XCUIElement.ElementType.secureTextField {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
                
        let characters = Array(text)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: characters.count)
        
        self.typeText(deleteString)
        self.typeText(text)
    }
    
    func clearText(_ text: String) {
        if self.elementType != XCUIElement.ElementType.textField && self.elementType != XCUIElement.ElementType.secureTextField {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        let characters = Array(text)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: characters.count)
        
        self.typeText(deleteString)
    }
    
    func enterText(_ text: String) {
        if self.elementType != XCUIElement.ElementType.textField && self.elementType != XCUIElement.ElementType.secureTextField {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        self.typeText(text)
    }
    
    func pasteText(app: XCUIApplication, _ text: String) {
        if self.elementType != XCUIElement.ElementType.textField && self.elementType != XCUIElement.ElementType.secureTextField {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        tap()
        
        sleep(1)
        
        UIPasteboard.general.string = text
        doubleTap()
        
        sleep(1)
        
        app.menuItems["Paste"].tap()
    }
}
