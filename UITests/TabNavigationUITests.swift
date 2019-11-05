//
//  TabNavigationUITests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest

class TabNavigationUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        launchApp()
        doLogin(username: "valid@test.com")
    }
   
    
    func testHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected)
    }
    
    func testBillTab() {
        let billTab = app.tabBars.buttons["Bill"]
        billTab.tap()
        XCTAssertTrue(billTab.isSelected)
    }
    
    func testOutageTab() {
        let outageTab = app.tabBars.buttons["Outage"]
        outageTab.tap()
        XCTAssertTrue(outageTab.isSelected)
    }
        
    func testMoreTab() {
        let moreTab = app.tabBars.buttons["More"]
        moreTab.tap()
        XCTAssertTrue(moreTab.isSelected)
    }
    
}
