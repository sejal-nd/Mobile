//
//  AppointmentsContainer.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AppointmentsContainer: Decodable {
    public var appointments: [AppointmentNew]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case appointments = "appointments"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.appointments = try data.decode([AppointmentNew].self,
                                            forKey: .appointments)
    }
}

public struct AppointmentNew: Decodable {
    public var id: String
    public var type: String
    public var typeID: String
    public var status: String
    public var statusID: String
    public var completionComments: Date?
    public var createDate: Date?
    public var lastAmendDate: Date?
    public var startDate: Date?
    public var timeSlot: String?
    public var stopDate: Date?
}
