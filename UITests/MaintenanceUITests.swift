//
//  MaintenanceUITests.swift
//  Mobile
//
//  Created by Samuel Francis on 2/11/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import XCTest

class MaintenanceUITests: ExelonUITestCase {

    func testMaintModeAll() {
        app.launchArguments.append("maintAll")
        launchApp()
        handleTermsFirstLaunch()
        
        tapButton(buttonText: "Sign In")
        
        checkExistenceOfElement(.button, "Reload")
        
        switch appOpCo {
        case .bge:
            checkExistenceOfElement(.staticText, "The BGE App is currently unavailable due to maintenance.")
            checkExistenceOfElement(.staticText, "If you smell natural gas, leave the area immediately and call BGE at 1-800-685-0123 or 1-877-778-7798\n\nIf your power is out or for downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .comEd:
            checkExistenceOfElement(.staticText, "The ComEd App is currently unavailable due to maintenance.")
            checkExistenceOfElement(.staticText, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .peco:
            checkExistenceOfElement(.staticText, "The PECO App is currently unavailable due to maintenance.")
            checkExistenceOfElement(.staticText, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        }
    }
    
    func testUnauthOutageMaintMode() {
        app.launchArguments.append("maintAllTabs")
        launchApp()
        handleTermsFirstLaunch()
        
        tapButton(buttonText: "CONTINUE AS GUEST")
        tapButton(buttonText: "Report Outage")
        
        switch appOpCo {
        case .bge:
            checkExistenceOfElement(.staticText, "If you smell natural gas, leave the area immediately and call BGE at 1-800-685-0123 or 1-877-778-7798\n\nIf your power is out or for downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .comEd:
            checkExistenceOfElement(.staticText, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .peco:
            checkExistenceOfElement(.staticText, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        }
    }
    
    func testMaintModeHomeBillCard() {
        app.launchArguments.append("maintNotHome")
        launchApp()
        doLogin(username: "default")
        
        checkExistenceOfElement(.staticText, "Billing is currently unavailable due to maintenance.")
    }
    
    func testMaintModeAllTabs() {
        app.launchArguments.append("maintAllTabs")
        launchApp()
        doLogin(username: "default")
        
        // Home
        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Home is currently unavailable due to maintenance.")
            ])
        
        // Bill
        selectTab(tabName: "Bill")
        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Billing is currently unavailable due to maintenance.")
            ])
        
        // Outage
        selectTab(tabName: "Outage")
        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Outage is currently unavailable due to")
            ])
        
        switch appOpCo {
        case .bge:
            checkExistenceOfElement(.staticText, "If you smell natural gas, leave the area immediately and call BGE at 1-800-685-0123 or 1-877-778-7798\n\nIf your power is out or for downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .comEd:
            checkExistenceOfElement(.staticText, "If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        case .peco:
            checkExistenceOfElement(.staticText, "If you smell natural gas or see downed power lines, leave the area immediately and then call PECO at 1-800-841-4141\n\nRepresentatives are available 24 hours a day, 7 days a week.")
        }
        
        // Usage
        selectTab(tabName: "Usage")
        checkExistenceOfElements([
            (.button, "Reload"),
            (.staticText, "Maintenance"),
            (.staticText, "Usage is currently unavailable due to maintenance.")
            ])
    }
}
