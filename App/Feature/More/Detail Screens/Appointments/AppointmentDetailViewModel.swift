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
    
    var contactNumber: String {
        switch Configuration.shared.opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-494-4000"
        case .comEd: return "1-800-334-7661"
        default: return ""
        }
    }
    
    var appointment: Appointment
    
    required init(appointment: Appointment) {
        self.appointment = appointment
    }
    
    var tabTitle: String {
        return appointment.date.monthDayOrdinalString
    }
    
    var status: Appointment.Status {
        return appointment.statusType
    }
    
    var showProgressView: Bool {
        switch status {
        case .scheduled: return true
        case .onOurWay: return true
        case .enRoute: return true
        case .inProgress: return true
        case .complete: return true
        case .canceled, .none: return false
        }
    }
    
    var showAdjustAlertPreferences: Bool {
        switch status {
        case .scheduled: return true
        case .onOurWay: return true
        case .enRoute: return true
        case .inProgress: return true
        case .complete: return false
        case .canceled, .none: return false
        }
    }
    
    var showCalendarButton: Bool {
        switch status {
        case .scheduled:
            return true
        case .onOurWay, .enRoute, .inProgress, .complete, .canceled, .none:
            return false
        }
    }
    
    var appointmentDescriptionText: NSAttributedString {
        let standardAttributes: [NSAttributedString.Key: Any] =
            [.font: OpenSans.regular.of(textStyle: .headline),
             .foregroundColor: UIColor.blackText]
        
        let statusType = appointment.statusType
        
        switch statusType {
        case .scheduled:
            return scheduledApptDescription
        case .onOurWay:
            fallthrough
        case .enRoute:
            return NSLocalizedString("Your technician is on their way for your appointment today.", comment: "")
                .attributedString(textAlignment: .center,
                                  otherAttributes: standardAttributes)
        case .inProgress:
            let boldText = String.localizedStringWithFormat("Estimated time of completion is %@.", formattedEndHour)
            let regularText = String.localizedStringWithFormat("Your appointment is in progress. %@", boldText)
            
            let attributedText = NSMutableAttributedString(string: regularText)
            attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                        range: NSMakeRange(0, regularText.count))
            attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                        range: NSMakeRange(0, attributedText.string.count))
            
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attributedText.addAttribute(.paragraphStyle, value: style,
                                        range: NSMakeRange(0, attributedText.string.count))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline), range: (regularText as NSString).range(of: boldText))
            
            return attributedText
        case .complete:
            return NSLocalizedString("Your appointment is complete. Please call for further assistance.", comment: "")
                .attributedString(textAlignment: .center,
                                  otherAttributes: standardAttributes)
        case .canceled:
            let boldText = appointment.date.dayMonthDayString
            let regularText = String.localizedStringWithFormat(
                """
                Your appointment scheduled for %@ has been canceled.\n
                We apologize for the inconvenience. Please contact us to reschedule.
                """
            , boldText)
            let attributedText = NSMutableAttributedString(attributedString: regularText.attributedString(textAlignment: .center, otherAttributes: standardAttributes))
            attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline), range: (regularText as NSString).range(of: boldText))
            return attributedText
        case .none:
            return NSLocalizedString("", comment: "")
            .attributedString(textAlignment: .center,
                              otherAttributes: standardAttributes)
        }
    }
    
    var scheduledApptDescription: NSMutableAttributedString {
        let regularText: String
        let boldText: String
        if appointment.date.isInToday(calendar: .opCo) {
            regularText = NSLocalizedString("Your appointment is ", comment: "")
        } else if appointment.date.isInTomorrow(calendar: .opCo) {
            regularText = NSLocalizedString("Your appointment is ", comment: "")
        } else {
            regularText = NSLocalizedString("Your appointment is scheduled for ", comment: "")
        }
        
        if Configuration.shared.opco != .peco, let stopDate = appointment.stopDate {
            if appointment.date.isInToday(calendar: .opCo) {
                boldText = String.localizedStringWithFormat("today between %@ - %@.",
                                                            appointment.date.hourAmPmString,
                                                            stopDate.hourAmPmString)
            } else if appointment.date.isInTomorrow(calendar: .opCo) {
                boldText = String.localizedStringWithFormat("tomorrow between %@ - %@.",
                                                            appointment.date.hourAmPmString,
                                                            stopDate.hourAmPmString)
            } else {
                boldText = String.localizedStringWithFormat("%@ between %@ - %@.",
                                                            appointment.date.dayMonthDayString,
                                                            appointment.date.hourAmPmString,
                                                            stopDate.hourAmPmString)
            }
        } else {
            if appointment.date.isInToday(calendar: .opCo) {
                boldText = String.localizedStringWithFormat("today between %@.", appointment.timeslot.displayString)
            } else if appointment.date.isInTomorrow(calendar: .opCo) {
                boldText = String.localizedStringWithFormat("tomorrow between %@.", appointment.timeslot.displayString)
            } else {
                boldText = String.localizedStringWithFormat("%@ between %@.", appointment.date.dayMonthDayString, appointment.timeslot.displayString)
            }
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
    }
    
    var formattedEndHour: String {
        if Configuration.shared.opco != .peco, let stopDate = appointment.stopDate {
            return stopDate.hourAmPmString
        } else {
            return appointment.timeslot.formattedEndHour
        }
    }
    
    var calendarEvent: EKEvent {
        let title = String.localizedStringWithFormat("My %@ appointment",
                                                     Configuration.shared.opco.displayString)
        
        let event = EKEvent(eventStore: EventStore.shared)
        event.title = title
        event.calendar = EventStore.shared.defaultCalendarForNewEvents
        event.availability = .busy
        event.location = AccountsStore.shared.currentAccount.address
        //event.url Coordinate with web for URLs and deep linking
        
        event.startDate = appointment.startTime
        event.endDate = appointment.endTime
        
        var alarms = [EKAlarm]()
        let now = Date.now
        if let appointmentStartTime = appointment.startTime, let alarmTime1 = Calendar.opCo.date(byAdding: DateComponents(day: -1), to: appointmentStartTime), alarmTime1 > now {
            alarms.append(EKAlarm(absoluteDate: alarmTime1))
        }
        
        if let appointmentStartTime = appointment.startTime, let alarmTime2 = Calendar.opCo.date(byAdding: DateComponents(hour: -1), to: appointmentStartTime), alarmTime2 > now {
            alarms.append(EKAlarm(absoluteDate: alarmTime2))
        }
        event.alarms = alarms
        

        return event
    }
}
