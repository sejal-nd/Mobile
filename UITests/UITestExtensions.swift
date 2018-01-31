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
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        let characters = Array(stringValue)
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: characters.count)
        
        self.typeText(deleteString)
        self.typeText(text)
    }
}
