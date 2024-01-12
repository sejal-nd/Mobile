//
//  AppointmentResponse.swift
//  Mobile
//
//  Created by Aolivas2 on 6/27/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation


// MARK: - AppoinmentRes
public struct AppointmentRes: Codable {
    var success: Bool?
    var data: [DataRes]?
}

// MARK: - Datum
public struct DataRes: Codable {
    var id, description, workSubType, workType: String?
    var propertyParameters: PropertyParameters?
    var fieldOrderID, type: String?
    var startDate, stopDate: Date?
    var createDate: String?
    var lastAmendDate: Date?
    var isRemote, isAllDay: Bool?
    var serviceLocation: ServiceLocation?
    var status: String?
    var locations: Locations?
    var workTasks: WorkTasks?
}

// MARK: - Locations
struct Locations: Codable {
}

// MARK: - PropertyParameters
struct PropertyParameters: Codable {
    var startDateTime: Date?
    var timeSlot: String?
    var stopDateTime: Date?
    var createdDateTime, timeSpecial, fieldOrderID, type: String?
    var status: String?
    var lastAmendDate: Date?
    var isRemote, isAllDay, somfa, faCharacteristic: String?
    var appointmentStatus: String?

    enum CodingKeys: String, CodingKey {
        case startDateTime, timeSlot, stopDateTime, createdDateTime, timeSpecial, fieldOrderID, type
        case status = "Status"
        case lastAmendDate, isRemote, isAllDay
        case somfa = "SOMFA"
        case faCharacteristic = "FACharacteristic"
        case appointmentStatus
    }
}

// MARK: - ServiceLocation
struct ServiceLocation: Codable {
    let serviceLocation: ServiceLocationClass

    enum CodingKeys: String, CodingKey {
        case serviceLocation = "ServiceLocation"
    }
}

// MARK: - ServiceLocationClass
struct ServiceLocationClass: Codable {
    var mRID, type: String?
}

// MARK: - WorkTasks
struct WorkTasks: Codable {
    var workTask: WorkTask?

    enum CodingKeys: String, CodingKey {
        case workTask = "WorkTask"
    }
}

// MARK: - WorkTask
struct WorkTask: Codable {
    var workLocation: WorkLocation?

    enum CodingKeys: String, CodingKey {
        case workLocation = "WorkLocation"
    }
}

// MARK: - WorkLocation
struct WorkLocation: Codable {
    let type: String
}
