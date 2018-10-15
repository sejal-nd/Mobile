//
//  AppointmentDetailViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 10/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import EventKit

class AppointmentDetailViewModel {
    
    let contactNumber = "1-800-685-0123"
    
    private let appointment: Appointment
    
    required init(appointment: Appointment) {
        self.appointment = appointment
    }
    
    var tabTitle: String {
        return appointment.startTime.monthDayOrdinalString
    }
    
    var status: Appointment.Status {
        return appointment.status
    }
    
    var caseNumberText: String {
        return String.localizedStringWithFormat("Case #%@", appointment.caseNumber)
    }
    
    var showProgressView: Bool {
        switch status {
        case .scheduled: return true
        case .enRoute: return true
        case .inProgress: return true
        case .complete: return true
        case .canceled: return false
        }
    }
    
    var showAdjustAlertPreferences: Bool {
        switch status {
        case .scheduled: return true
        case .enRoute: return true
        case .inProgress: return true
        case .complete: return false
        case .canceled: return false
        }
    }
    
    var showUpperContactButton: Bool {
        switch status {
        case .scheduled: return false
        case .enRoute: return false
        case .inProgress: return true
        case .complete: return true
        case .canceled: return true
        }
    }
    
    var showHowToPrepare: Bool {
        return !showUpperContactButton
    }
    
    var appointmentDescriptionText: NSAttributedString {
        let standardAttributes: [NSAttributedString.Key: Any] =
            [.font: OpenSans.regular.of(textStyle: .headline),
             .foregroundColor: UIColor.blackText]
        
        switch appointment.status {
        case .scheduled:
            let regularText: String
            let boldText: String
            if Calendar.opCo.isDateInToday(appointment.startTime) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("today between %@ - %@.",
                                                            appointment.startTime.hour_AmPmString,
                                                            appointment.endTime.hour_AmPmString)
            } else if Calendar.opCo.isDateInTomorrow(appointment.startTime) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("tomorrow between %@ - %@.",
                                                            appointment.startTime.hour_AmPmString,
                                                            appointment.endTime.hour_AmPmString)
            } else {
                regularText = NSLocalizedString("Your appointment is scheduled for ", comment: "")
                boldText = String.localizedStringWithFormat("%@ between %@ - %@.",
                                                            appointment.startTime.dayMonthDayString,
                                                            appointment.startTime.hour_AmPmString,
                                                            appointment.endTime.hour_AmPmString)
            }
            
            let attributedText = NSMutableAttributedString(string: regularText + boldText)
            attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                        range: NSMakeRange(0, regularText.count))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                        range: NSMakeRange(regularText.count, boldText.count))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                        range: NSMakeRange(regularText.count, boldText.count))
            attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attributedText.addAttribute(.paragraphStyle, value: style,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            return attributedText
        case .enRoute:
            return NSLocalizedString("Your technician is on their way for your appointment today.", comment: "")
                .attributedString(textAlignment: .center,
                                  otherAttributes: standardAttributes)
        case .inProgress:
            let regularText = NSLocalizedString("Your appointment is in progress. ", comment: "")
            let boldText = String.localizedStringWithFormat("Estimated time of completion is %@.",
                                                            appointment.endTime.hour_AmPmString)
            
            let attributedText = NSMutableAttributedString(string: regularText + boldText)
            attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                        range: NSMakeRange(0, regularText.count))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                        range: NSMakeRange(regularText.count, boldText.count))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                        range: NSMakeRange(regularText.count, boldText.count))
            attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attributedText.addAttribute(.paragraphStyle, value: style,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            return attributedText
        case .complete:
            let localizedText = String.localizedStringWithFormat("Your appointment is complete. For further assistance, please call %@.", contactNumber)
            
            let attributedText = NSMutableAttributedString(string: localizedText)
            attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                        range: NSMakeRange(0, attributedText.string.count))
            attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                        range: NSMakeRange(0, localizedText.count))
            attributedText.addAttribute(.font, value: OpenSans.semibold.of(textStyle: .headline),
                                        range: NSMakeRange(localizedText.count - self.contactNumber.count - 1, self.contactNumber.count))
            
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attributedText.addAttribute(.paragraphStyle, value: style,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            return attributedText
        case .canceled:
            return NSLocalizedString("Your appointment has been canceled due to inclement weather.", comment: "")
                .attributedString(textAlignment: .center,
                                  otherAttributes: standardAttributes)
        }
    }
    
    func addCalendarEvent() -> Observable<Void> {
        let title = String.localizedStringWithFormat("My %@ appointment",
                                                     Environment.shared.opco.displayString)
        let description = String.localizedStringWithFormat("The appointment case number is %@",
                                                           appointment.caseNumber)
        
        return CalendarService().addEventToCalendar(title: title,
                                                    description: description,
                                                    startDate: appointment.startTime,
                                                    endDate: appointment.endTime)
    }
    
    let eventStore = EKEventStore()
    
    private(set) lazy var calendarEvent: EKEvent = {
        let title = String.localizedStringWithFormat("My %@ appointment",
                                                     Environment.shared.opco.displayString)
        let description = String.localizedStringWithFormat("The appointment case number is %@",
                                                           appointment.caseNumber)
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = appointment.startTime
        event.endDate = appointment.endTime
        event.notes = description
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.availability = .busy
        //event.url Coordinate with web for URLs and deep linking
        return event
    }()
}
