//
//  OutageTests.swift
//  BGE
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest


class OutageUITests: ExelonUITestCase {
    
    override func setUp() {
        super.setUp()
        launchApp()
    }
        
    func testPowerOnState() {
        doLogin(username: "default")
        selectTab(tabName: "Outage")
        
        checkExistenceOfElements([
            (.cell, "Report Outage"),
            (.cell, "View Outage Map")
        ])
        
        if appOpCo == .comEd {
            checkExistenceOfElement(.cell, "Report Streetlight Outage")
        }
        
        tapButton(buttonText: "View Details")

        XCTAssertTrue(app.staticTexts["test power on message"].waitForExistence(timeout: 3))
    }
    
    func testPowerOutState() {
        doLogin(username: "outagePowerOut")
        selectTab(tabName: "Outage")
        tapButton(buttonText: "View Details")
                
        XCTAssertTrue(app.staticTexts["test power out message"].waitForExistence(timeout: 3))
    }
    
    func testGasOnlyState() {
        doLogin(username: "gasOnly")
        selectTab(tabName: "Outage")

        XCTAssertTrue(staticTextElement(withText: "Gas Only Account").exists)
        XCTAssertFalse(staticTextElement(withText: "Our records indicate").exists) // Should not be an outage status button
    }
    
    func testFinaledState() {
        doLogin(username: "finaled")
        selectTab(tabName: "Outage")
        
        XCTAssertTrue(staticTextElement(withText: "Outage Unavailable").exists)
        XCTAssertFalse(staticTextElement(withText: "Our records indicate").exists)
            
        
        let tableView = app.tables.matching(identifier: "outageTableView")
        let cell = tableView.cells.element(matching: .cell, identifier: "Report Outage")
        
        XCTAssertTrue(cell.exists)
        XCTAssertFalse(cell.isEnabled, "Report outage button should be disabled for finaled accounts")
        
        checkExistenceOfElement(.cell, "View Outage Map")
        
        if appOpCo == .comEd {
            checkExistenceOfElement(.cell, "Report Streetlight Outage")
        }
    }
    
    func testReportOutage() {
        doLogin(username: "default")
        selectTab(tabName: "Outage")

        let tableView = app.tables.matching(identifier: "outageTableView")
        let cell = tableView.cells.element(matching: .cell, identifier: "Report Outage")
        cell.tap()
        
        tapButton(buttonText: "Report Outage")

        checkExistenceOfElements([
            (.staticText, "Your outage is"),
            (.staticText, "REPORTED")
        ])
        XCTAssertTrue(cell.staticTexts["detail"].label != "")
    }
}
