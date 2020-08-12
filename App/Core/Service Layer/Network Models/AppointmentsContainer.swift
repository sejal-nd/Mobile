//
//  AppointmentsContainer.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AppointmentsContainer: Decodable {
    public var appointments: [Appointment]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case appointments = "appointments"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.appointments = try data.decode([Appointment].self,
                                            forKey: .appointments)
    }
}
