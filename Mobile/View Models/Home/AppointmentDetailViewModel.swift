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
    
    var appointment: Appointment
    
    required init(appointment: Appointment) {
        self.appointment = appointment
    }
    
    var tabTitle: String {
        return appointment.startDate.monthDayOrdinalString
    }
    
    var status: Appointment.Status {
        return appointment.status
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
    
    var showCalendarButton: Bool {
        switch status {
        case .scheduled:
            return true
        case .enRoute, .inProgress, .complete, .canceled:
            return false
        }
    }
    
    var appointmentDescriptionText: NSAttributedString {
        let standardAttributes: [NSAttributedString.Key: Any] =
            [.font: OpenSans.regular.of(textStyle: .headline),
             .foregroundColor: UIColor.blackText]
        
        switch appointment.status {
        case .scheduled:
            let regularText: String
            let boldText: String
            if Calendar.opCo.isDateInToday(appointment.startDate) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("today between %@ - %@.",
                                                            appointment.startDate.hourAmPmString,
                                                            appointment.stopDate.hourAmPmString)
            } else if Calendar.opCo.isDateInTomorrow(appointment.startDate) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("tomorrow between %@ - %@.",
                                                            appointment.startDate.hourAmPmString,
                                                            appointment.stopDate.hourAmPmString)
            } else {
                regularText = NSLocalizedString("Your appointment is scheduled for ", comment: "")
                boldText = String.localizedStringWithFormat("%@ between %@ - %@.",
                                                            appointment.startDate.dayMonthDayString,
                                                            appointment.startDate.hourAmPmString,
                                                            appointment.stopDate.hourAmPmString)
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
                                                            appointment.stopDate.hourAmPmString)
            
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
            return NSLocalizedString("Your appointment is complete. Please call for further assistance.", comment: "")
                .attributedString(textAlignment: .center,
                                  otherAttributes: standardAttributes)
        case .canceled:
            let boldText = appointment.startDate.dayMonthDayString
            let regularText = String.localizedStringWithFormat(
                """
                Your appointment scheduled for %@ has been canceled.\n
                We apologize for the inconvenience. Please contact us to reschedule.
                """
            , boldText)
            let attributedText = NSMutableAttributedString(attributedString: regularText.attributedString(textAlignment: .center, otherAttributes: standardAttributes))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline), range: (regularText as NSString).range(of: boldText))
            return attributedText
        }
    }
    
    var calendarEvent: EKEvent {
        let title = String.localizedStringWithFormat("My %@ appointment",
                                                     Environment.shared.opco.displayString)
        
        let event = EKEvent(eventStore: EventStore.shared)
        event.title = title
        event.startDate = appointment.startDate
        event.endDate = appointment.stopDate
        event.calendar = EventStore.shared.defaultCalendarForNewEvents
        event.availability = .busy
        event.location = AccountsStore.shared.currentAccount.address
        //event.url Coordinate with web for URLs and deep linking
        
        var alarms = [EKAlarm]()
        let now = Date()
        if let alarmTime1 = Calendar.opCo.date(byAdding: DateComponents(day: -1), to: appointment.startDate), alarmTime1 > now {
            alarms.append(EKAlarm(absoluteDate: alarmTime1))
        }
        
        if let alarmTime2 = Calendar.opCo.date(byAdding: DateComponents(hour: -1), to: appointment.startDate), alarmTime2 > now {
            alarms.append(EKAlarm(absoluteDate: alarmTime2))
        }
        
        event.alarms = alarms
        
        return event
    }
}
