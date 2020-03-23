//
//  AdminService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AdminService {
    static func checkMinVersion(completion: @escaping (Result<String, Error>) -> ()) {
        ServiceLayer.request(router: .minVersion) { (result: Result<NewVersion, Error>) in
            switch result {
            case .success(let data):
                print("NetworkTest 1 SUCCESS: \(data) BREAK \(data.min)")
                completion(.success(data.min))
            case .failure(let error):
                print("NetworkTest 1 FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
}
