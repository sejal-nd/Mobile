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
