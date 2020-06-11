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
    
    let viewModel = AppointmentDetailViewModel(appointment: getAppointment(forKey: .apptToday)) // Don't worry about this appointment, we'll override in every test
    let disposeBag = DisposeBag()
    
    func testTabTitle() {
        let expectedTabTitles = ["Oct 31st", "Aug 2nd", "Jan 3rd", "Mar 4th"]
        let appointments = getAppointments(forKeys: .apptDateNumberSt, .apptDateNumberNd, .apptDateNumberRd, .apptDateNumberTh)
        for (appointment, expectedTabTitle) in zip(appointments, expectedTabTitles) {
            viewModel.appointment = appointment
            XCTAssertEqual(viewModel.tabTitle, expectedTabTitle)
        }
    }
    
    func testShowProgressView() {
        let expectedValues = [true, true, true, true, false]
        let appointments = getAppointments(forKeys: .apptScheduled, .apptEnRoute, .apptInProgress, .apptComplete, .apptCanceled)
        for (appointment, expectedValue) in zip(appointments, expectedValues) {
            viewModel.appointment = appointment
            XCTAssertEqual(viewModel.showProgressView, expectedValue)
        }
    }
    
    func testShowAdjustAlertPreferences() {
        let expectedValues = [true, true, true, false, false]
        let appointments = getAppointments(forKeys: .apptScheduled, .apptEnRoute, .apptInProgress, .apptComplete, .apptCanceled)
        for (appointment, expectedValue) in zip(appointments, expectedValues) {
            viewModel.appointment = appointment
            XCTAssertEqual(viewModel.showAdjustAlertPreferences, expectedValue)
        }
    }
    
    func testShowCalendarButton() {
        let expectedValues = [true, false, false, false, false]
        let appointments = getAppointments(forKeys: .apptScheduled, .apptEnRoute, .apptInProgress, .apptComplete, .apptCanceled)
        for (appointment, expectedValue) in zip(appointments, expectedValues) {
            viewModel.appointment = appointment
            XCTAssertEqual(viewModel.showCalendarButton, expectedValue)
        }
    }
    
    // Only testing the actual string, ignoring attributed values
    func testAppointmentDescriptionText() {
        // Scheduled today
        viewModel.appointment = getAppointment(forKey: .apptToday)
        var expectedDescription = "Your appointment is today between 8AM - 12PM."
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, expectedDescription)
        
        // Scheduled tomorrow
        viewModel.appointment = getAppointment(forKey: .apptTomorrow)
        expectedDescription = "Your appointment is tomorrow between 8AM - 12PM."
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, expectedDescription)
        
        // Scheduled beyond tomorrow
        viewModel.appointment = getAppointment(forKey: .apptScheduled)
        expectedDescription = "Your appointment is scheduled for Sunday, Jan 6th between 12PM - 5PM."
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, expectedDescription)
        
        // En Route
        viewModel.appointment = getAppointment(forKey: .apptEnRoute)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, "Your technician is on their way for your appointment today.")
        
        // In Progress
        viewModel.appointment = getAppointment(forKey: .apptInProgress)
        
        var hourAmPm: String
        
        switch Environment.shared.opco {
        case .bge:
            hourAmPm = "1PM"
        case .peco:
            hourAmPm = "2PM"
        case .comEd:
            hourAmPm = "12PM"
        }
        
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, "Your appointment is in progress. Estimated time of completion is \(hourAmPm).")
        
        // Complete
        viewModel.appointment = getAppointment(forKey: .apptComplete)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, "Your appointment is complete. Please call for further assistance.")
        
        // Canceled
        viewModel.appointment = getAppointment(forKey: .apptCanceled)
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, "Your appointment scheduled for Tuesday, Jan 1st has been canceled.\n\nWe apologize for the inconvenience. Please contact us to reschedule.")
    }
    
    func testCalendarEvent() {
        MockUser.current = MockUser(globalKeys: .residential)
        MockAccountService.loadAccountsSync()
        
        let expectedStartDate = Calendar.opCo.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let expectedStopDate = Calendar.opCo.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        
        viewModel.appointment = getAppointments(forKeys: .apptToday).first!
        
        let calEvent = viewModel.calendarEvent
        XCTAssertEqual(calEvent.title, String.localizedStringWithFormat("My %@ appointment", Environment.shared.opco.displayString))
        XCTAssertEqual(calEvent.startDate, expectedStartDate)
        XCTAssertEqual(calEvent.endDate, expectedStopDate)
        XCTAssertEqual(calEvent.location, "123 Main Street")
    }
    
}

fileprivate func getAppointments(forKeys keys: MockDataKey..., file: StaticString = #file, line: UInt = #line) -> [Appointment] {
    do {
        return try keys.map {
            let appointments = try MockJSONManager.shared.mappableArray(fromFile: .appointments, key: $0) as [Appointment]
            guard let appointment = appointments.first else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue,
                                   serviceMessage: "failed to grab appointments for key \($0.rawValue)")
            }
            
            return appointment
        }
    } catch {
        XCTFail("Error: \(error.localizedDescription)", file: file, line: line)
        return []
    }
}

fileprivate func getAppointment(forKey key: MockDataKey, file: StaticString = #file, line: UInt = #line) -> Appointment {
    return getAppointments(forKeys: key).first!
}
