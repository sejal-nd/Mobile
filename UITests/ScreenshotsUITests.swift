//
//  ScreenshotsUITests.swift
//  Mobile
//
//  Created by Samuel Francis on 2/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import XCTest

class ScreenshotsUITests: ExelonUITestCase {

    func testScreenshots() {
        launchApp()
        
        doLogin(username: "screenshots")
        
        // Get rid of the personalize home button if present
        let personalizeButton = buttonElement(withText: "Did you know you can personalize your home screen?")
        if personalizeButton.exists {
            personalizeButton.tap()
            tapButton(buttonText: "Save Changes")
        }

        // 📸 Home

        selectTab(tabName: "Bill")
        // 📸 Bill
        
        selectTab(tabName: "Outage")
        tapButton(buttonText: "Report Outage")
        tapButton(buttonText: "Submit")
        sleep(6) // wait for the toast to dismiss
        // 📸 Outage
        
        selectTab(tabName: "Usage")
        // 📸 Usage
        
        // Terminate and relaunch with storm mode
        app.terminate()
        app.launchArguments.append("stormMode")
        launchApp()
        doLogin(username: "screenshots")
        // 📸 Storm Mode
    }

}
