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
    
    static func maintenanceMode(completion: @escaping (Result<NewMaintenanceMode, Error>) -> ()) {
        NetworkingLayer.request(router: .maintenanceMode) { (result: Result<NewMaintenanceMode, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
