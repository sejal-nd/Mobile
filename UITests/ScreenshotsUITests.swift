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
        setupSnapshot(app)
        
        launchApp()
    
        doLogin(username: "screenshots")
        
        // Get rid of the personalize home button if present
        let personalizeButton = buttonElement(withText: "Did you know you can personalize your home screen?")
        if personalizeButton.exists {
            personalizeButton.tap()
            tapButton(buttonText: "Save Changes")
        }

        // 📸 Home
        snapshot("01Home")
        
        // 📸 Bill
        selectTab(tabName: "Bill")
        snapshot("02Bill")
        
        selectTab(tabName: "Outage")
        
        sleep(5)
        app.staticTexts["Report Outage"].tap()
        tapButton(buttonText: "Report Outage")
        sleep(6) // wait for the toast to dismiss
        
        // 📸 Outage
        snapshot("03Outage")
        
        
        // 📸 Usage
        selectTab(tabName: "Usage")
        snapshot("04Usage")
        
        // Terminate and relaunch with storm mode
        app.terminate()
        app.launchArguments.append("stormMode")
        launchApp()
        doLogin(username: "screenshots")
        // 📸 Storm Mode
        snapshot("05Storm")
    }

}
