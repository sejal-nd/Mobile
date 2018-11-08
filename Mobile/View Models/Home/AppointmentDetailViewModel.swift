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
            if Calendar.opCo.isDateInToday(appointment.startDate) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("today between %@ - %@.",
                                                            appointment.startDate.hour_AmPmString,
                                                            appointment.stopDate.hour_AmPmString)
            } else if Calendar.opCo.isDateInTomorrow(appointment.startDate) {
                regularText = NSLocalizedString("Your appointment is ", comment: "")
                boldText = String.localizedStringWithFormat("tomorrow between %@ - %@.",
                                                            appointment.startDate.hour_AmPmString,
                                                            appointment.stopDate.hour_AmPmString)
            } else {
                regularText = NSLocalizedString("Your appointment is scheduled for ", comment: "")
                boldText = String.localizedStringWithFormat("%@ between %@ - %@.",
                                                            appointment.startDate.dayMonthDayString,
                                                            appointment.startDate.hour_AmPmString,
                                                            appointment.stopDate.hour_AmPmString)
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
                                                            appointment.stopDate.hour_AmPmString)
            
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
    
    var calendarEvent: EKEvent {
        let title = String.localizedStringWithFormat("My %@ appointment",
                                                     Environment.shared.opco.displayString)
        let description = String.localizedStringWithFormat("The appointment case number is %@",
                                                           appointment.caseNumber)
        
        let event = EKEvent(eventStore: EventStore.shared)
        event.title = title
        event.startDate = appointment.startDate
        event.endDate = appointment.stopDate
        event.notes = description
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
