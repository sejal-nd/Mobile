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
    
    let viewModel = AppointmentDetailViewModel(appointment: Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "0")) // Don't worry about this appointment, we'll override in every test
    let disposeBag = DisposeBag()
    
    func testTabTitle() {
        let st = Calendar.opCo.date(from: DateComponents(year: 2018, month: 10, day: 31))!
        viewModel.appointment = Appointment(jobId: "0", startTime: st, endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.tabTitle, "Oct 31st")
        
        let nd = Calendar.opCo.date(from: DateComponents(year: 2018, month: 8, day: 2))!
        viewModel.appointment = Appointment(jobId: "0", startTime: nd, endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.tabTitle, "Aug 2nd")
        
        let rd = Calendar.opCo.date(from: DateComponents(year: 2018, month: 1, day: 3))!
        viewModel.appointment = Appointment(jobId: "0", startTime: rd, endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.tabTitle, "Jan 3rd")
        
        let th = Calendar.opCo.date(from: DateComponents(year: 2018, month: 3, day: 4))!
        viewModel.appointment = Appointment(jobId: "0", startTime: th, endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.tabTitle, "Mar 4th")
    }
    
    func testCaseNumberText() {
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "813")
        XCTAssertEqual(viewModel.caseNumberText, NSLocalizedString("Case #813", comment: ""))
    }
    
    func testShowProgressView() {
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .enRoute, caseNumber: "0")
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .inProgress, caseNumber: "0")
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .complete, caseNumber: "0")
        XCTAssertTrue(viewModel.showProgressView)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .canceled, caseNumber: "0")
        XCTAssertFalse(viewModel.showProgressView)
    }
    
    func testShowAdjustAlertPreferences() {
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .enRoute, caseNumber: "0")
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .inProgress, caseNumber: "0")
        XCTAssertTrue(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .complete, caseNumber: "0")
        XCTAssertFalse(viewModel.showAdjustAlertPreferences)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .canceled, caseNumber: "0")
        XCTAssertFalse(viewModel.showAdjustAlertPreferences)
    }
    
    func testShowUpperContactButton() {
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertFalse(viewModel.showUpperContactButton)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .enRoute, caseNumber: "0")
        XCTAssertFalse(viewModel.showUpperContactButton)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .inProgress, caseNumber: "0")
        XCTAssertTrue(viewModel.showUpperContactButton)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .complete, caseNumber: "0")
        XCTAssertTrue(viewModel.showUpperContactButton)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .canceled, caseNumber: "0")
        XCTAssertTrue(viewModel.showUpperContactButton)
    }
    
    func testShowHowToPrepare() {
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .scheduled, caseNumber: "0")
        XCTAssertTrue(viewModel.showHowToPrepare)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .enRoute, caseNumber: "0")
        XCTAssertTrue(viewModel.showHowToPrepare)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .inProgress, caseNumber: "0")
        XCTAssertFalse(viewModel.showHowToPrepare)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .complete, caseNumber: "0")
        XCTAssertFalse(viewModel.showHowToPrepare)
        
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .canceled, caseNumber: "0")
        XCTAssertFalse(viewModel.showHowToPrepare)
    }
    
    // Only testing the actual string, ignoring attributed values
    func testAppointmentDescriptionText() {
        // Scheduled today
        let today2 = Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        let today3 = Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        viewModel.appointment = Appointment(jobId: "0", startTime: today2, endTime: today3, status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is today between 2 PM - 3 PM.", comment: ""))
        
        // Scheduled tomorrow (also tests half hour round ups)
        let tomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: Date())!
        let tomorrow230 = Calendar.opCo.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow)!
        let tomorrow330 = Calendar.opCo.date(bySettingHour: 15, minute: 30, second: 0, of: tomorrow)!
        viewModel.appointment = Appointment(jobId: "0", startTime: tomorrow230, endTime: tomorrow330, status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is tomorrow between 3 PM - 4 PM.", comment: ""))
        
        // Scheduled beyond tomorrow (also tests half hour round downs)
        let superFutureDate = Calendar.opCo.date(from: DateComponents(year: 2100, month: 10, day: 31))! // So we never have to worry about tests going out of date
        let future9 = Calendar.opCo.date(bySettingHour: 9, minute: 15, second: 0, of: superFutureDate)!
        let future11 = Calendar.opCo.date(bySettingHour: 11, minute: 15, second: 0, of: superFutureDate)!
        viewModel.appointment = Appointment(jobId: "0", startTime: future9, endTime: future11, status: .scheduled, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is scheduled for Sunday, Oct 31st between 9 AM - 11 AM.", comment: ""))
        
        // En Route
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .enRoute, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your technician is on their way for your appointment today.", comment: ""))
        
        // In Progress
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: today3, status: .inProgress, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is in progress. Estimated time of completion is 3 PM.", comment: ""))
        
        // Complete
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .complete, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment is complete. For further assistance, please call 1-800-685-0123.", comment: ""))
        
        // Canceled
        viewModel.appointment = Appointment(jobId: "0", startTime: Date(), endTime: Date(), status: .canceled, caseNumber: "0")
        XCTAssertEqual(viewModel.appointmentDescriptionText.string, NSLocalizedString("Your appointment has been canceled due to inclement weather.", comment: ""))
    }
    
    func testCalendarEvent() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "0", address: "123 Main Street", premises: [], currentPremise: nil, status: nil, isLinked: false, isDefault: false, isFinaled: false, isResidential: true, serviceType: nil)
        let today2 = Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        let today3 = Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        viewModel.appointment = Appointment(jobId: "0", startTime: today2, endTime: today3, status: .scheduled, caseNumber: "813")
        
        let calEvent = viewModel.calendarEvent
        XCTAssertEqual(calEvent.title, String.localizedStringWithFormat("My %@ appointment", Environment.shared.opco.displayString))
        XCTAssertEqual(calEvent.startDate, today2)
        XCTAssertEqual(calEvent.endDate, today3)
        XCTAssertEqual(calEvent.notes, NSLocalizedString("The appointment case number is 813", comment: ""))
        XCTAssertEqual(calEvent.location, "123 Main Street")
    }
    
}
