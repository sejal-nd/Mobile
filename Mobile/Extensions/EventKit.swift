//
//  EventKit.swift
//  Mobile
//
//  Created by Samuel Francis on 10/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import EventKit
import RxSwift

class CalendarService {
    
    func addEventToCalendar(title: String,
                            description: String?,
                            startDate: Date,
                            endDate: Date) -> Observable<Void> {
        let eventStore = EKEventStore()
        
        return Observable<Void>.create { observer in
            eventStore.requestAccess(to: .event) { (granted, error) in
                if let error = error, !granted {
                    observer.onError(error)
                    return
                }
                
                let event = EKEvent(eventStore: eventStore)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.notes = description
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    observer.onNext(())
                    observer.onCompleted()
                    return
                } catch let e {
                    observer.onError(e)
                    return
                }
            }
            
            return Disposables.create()
        }
        
        
    }
}


