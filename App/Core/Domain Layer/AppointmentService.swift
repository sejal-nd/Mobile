//
//  AppointmentService.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/29/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum AppointmentService {
    static func fetchAppointments(accountNumber: String, premiseNumber: String, completion: @escaping (Result<AppointmentsContainer, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .appointments(accountNumber: accountNumber, premiseNumber: premiseNumber), completion: completion)
    }
}
