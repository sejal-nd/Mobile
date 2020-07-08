//
//  AdminService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AnonymousService {
    static func checkMinVersion(completion: @escaping (Result<String, Error>) -> ()) {
        NetworkingLayer.request(router: .minVersion) { (result: Result<NewVersion, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data.min))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func maintenanceMode(shouldPostNotification: Bool = false, completion: @escaping (Result<MaintenanceMode, Error>) -> ()) {
        NetworkingLayer.request(router: .maintenanceMode) { (result: Result<MaintenanceMode, NetworkingError>) in
            switch result {
            case .success(let maintenanceMode):
                if maintenanceMode.all && shouldPostNotification {
                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: maintenanceMode)
                }
                
                completion(.success(maintenanceMode))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
