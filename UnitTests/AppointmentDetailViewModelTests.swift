//
//  AppointmentDetailViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 10/30/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import EventKit

class AppointmentDetailViewModelTests: XCTestCase {
    
    let viewModel = AppointmentDetailViewModel(appointment: Appointment(id: "0", startDate: .now, stopDate: .now, status: .scheduled)) // Don't worry about this appointment, we'll override in every test
    let disposeBag = DisposeBag()
    
    func testTabTitle() {
        let st = Calendar.opCo.date(from: DateComponents(year: 2018, month: 10, day: 31))!
        viewModel.appointment = Appointment(id: "0", startDate: st, stopDate: .now, status: .scheduled)
        XCTAssertEqual(viewModel.tabTitle, "Oct 31st")
        
        let nd = Calendar.opCo.date(from: DateComponents(year: 2018, month: 8, day: 2))!
        viewModel.appointment = Appointment(id: "0", startDate: nd, stopDate: .now, status: .scheduled)
        XCTAssertEqual(viewModel.tabTitle, "Aug 2nd")
        
        let rd = Calendar.opCo.date(from: DateComponents(year: 2018, month: 1, day: 3))!
        viewModel.appointment = Appointment(id: "0", startDate: rd, stopDate: .now, status: .scheduled)
        XCTAssertEqual(viewModel.tabTitle, "Jan 3rd")
        
        let th = Calendar.opCo.date(from: DateComponents(year: 2018, month: 3, day: 4))!
        viewModel.appointment = Appointment(id: "0", startDate: th, stopDate: .now, status: .scheduled)
        XCTAssertEqual(viewModel.tabTitle, "Mar 4th")
    }
    
    func testShowProgressView() {
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .scheduled)
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .enRoute)
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .inProgress)
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .complete)
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .canceled)
        XCTAssertFalse(viewModel.showProgressView)
    }
    
    func testShowAdjustAlertPreferences() {
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .scheduled)
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .enRoute)
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .inProgress)
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .complete)
        XCTAssertFalse(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .canceled)
        XCTAssertFalse(viewModel.showAdjustAlertPreferences)
    }
    
    func testShowCalendarButton() {
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .scheduled)
        XCTAssertTrue(viewModel.showCalendarButton)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .enRoute)
        XCTAssertFalse(viewModel.showCalendarButton)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .inProgress)
        XCTAssertFalse(viewModel.showCalendarButton)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .complete)
        XCTAssertFalse(viewModel.showCalendarButton)
        
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .canceled)
        XCTAssertFalse(viewModel.showCalendarButton)
    }
    
    // Only testing the actual string, ignoring attributed values
    func testAppointmentDescriptionText() {
        // Scheduled today
        let today2 = Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: .now)!
        let today3 = Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: .now)!
        viewModel.appointment = Appointment(id: "0", startDate: today2, stopDate: today3, status: .scheduled)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is today between 2PM - 3PM.", comment: ""))
        
        // Scheduled tomorrow (also tests half hour round ups)
        let tomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: .now)!
        let tomorrow230 = Calendar.opCo.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow)!
        let tomorrow330 = Calendar.opCo.date(bySettingHour: 15, minute: 30, second: 0, of: tomorrow)!
        viewModel.appointment = Appointment(id: "0", startDate: tomorrow230, stopDate: tomorrow330, status: .scheduled)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is tomorrow between 3PM - 4PM.", comment: ""))
        
        // Scheduled beyond tomorrow (also tests half hour round downs)
        let superFutureDate = Calendar.opCo.date(from: DateComponents(year: 2100, month: 10, day: 31))! // So we never have to worry about tests going out of date
        let future9 = Calendar.opCo.date(bySettingHour: 9, minute: 15, second: 0, of: superFutureDate)!
        let future11 = Calendar.opCo.date(bySettingHour: 11, minute: 15, second: 0, of: superFutureDate)!
        viewModel.appointment = Appointment(id: "0", startDate: future9, stopDate: future11, status: .scheduled)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is scheduled for Sunday, Oct 31st between 9AM - 11AM.", comment: ""))
        
        // En Route
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .enRoute)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your technician is on their way for your appointment today.", comment: ""))
        
        // In Progress
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: today3, status: .inProgress)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is in progress. Estimated time of completion is 3PM.", comment: ""))
        
        // Complete
        viewModel.appointment = Appointment(id: "0", startDate: .now, stopDate: .now, status: .complete)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is complete. Please call for further assistance.", comment: ""))
        
        // Canceled
        viewModel.appointment = Appointment(id: "0", startDate: future9, stopDate: future11, status: .canceled)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment scheduled for Sunday, Oct 31st has been canceled.\n\nWe apologize for the inconvenience. Please contact us to reschedule.", comment: ""))
    }
    
    func testCalendarEvent() {
        AccountsStore.shared.accounts = [Account(accountNumber: "0", address: "123 Main Street", premises: [], currentPremise: nil, status: nil, isLinked: false, isDefault: false, isFinaled: false, isResidential: true, serviceType: nil)]
        AccountsStore.shared.currentIndex = 0
        
        let today2 = Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: .now)!
        let today3 = Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: .now)!
        viewModel.appointment = Appointment(id: "0", startDate: today2, stopDate: today3, status: .scheduled)
        
        let calEvent = viewModel.calendarEvent
        XCTAssertEqual(calEvent.title, String.localizedStringWithFormat("My %@ appointment", Environment.shared.opco.displayString))
        XCTAssertEqual(calEvent.startDate, today2)
        XCTAssertEqual(calEvent.endDate, today3)
        XCTAssertEqual(calEvent.location, "123 Main Street")
    }
    
}
