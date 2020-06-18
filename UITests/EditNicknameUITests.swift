//
//  EditNicknameUITests.swift
//  Mobile
//
//  Created by Majumdar, Amit on 18/06/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import XCTest

class EditNicknameUITests: ExelonUITestCase {

    override func setUp() {
        super.setUp()
        launchApp()
    }

    func testEditNicknamePageLayout() {
        checkExistenceOfElements([
            (.textField, "Account Nickname"),
            (.button, "Save Nickname"),
            (.button, "Back")
        ])
    }
}
