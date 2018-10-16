//
//  EventStore.swift
//  Mobile
//
//  Created by Samuel Francis on 10/16/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import EventKit

struct EventStore {
    static let shared = EKEventStore()
    
    private init() {}
}
